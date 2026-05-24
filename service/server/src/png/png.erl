-module(png).
-export([parse_png/1, build_idat/1, defilter_image/5]).

build_idat(CompressedIoList) ->
    Length = erlang:iolist_size(CompressedIoList),
    CRC = erlang:crc32(["IDAT", CompressedIoList]),
    [<<Length:32, "IDAT">>, CompressedIoList, <<CRC:32>>].

%% uncompresses
parse_png(<<137, 80, 78, 71, 13, 10, 26, 10, Rest/binary>>) ->
    Signature = <<137, 80, 78, 71, 13, 10, 26, 10>>,
    parse_chunks(Rest, Signature, <<>>, <<>>, {});
parse_png(BadBinary) ->
    erlang:display({~"BAD PNG SIGNATURE", BadBinary}),
    erlang:error(invalid_signature).


%% extract width from ihdr, keep building the header envelope
parse_chunks(<<Length:32, "IHDR", Data:Length/binary, CRC:32, Rest/binary>>, Headers, IDATs, Footer, _Meta) ->
    <<W:32, H:32, BitDepth:8, ColorType:8, _/binary>> = Data,
    NewHeaders = <<Headers/binary, Length:32, "IHDR", Data/binary, CRC:32>>,
    parse_chunks(Rest, NewHeaders, IDATs, Footer, {W, H, BitDepth, ColorType});

%% extract idats and combine them
parse_chunks(<<Length:32, "IDAT", Data:Length/binary, _CRC:32, Rest/binary>>, Headers, IDATs, Footer, Meta) ->
    parse_chunks(Rest, Headers, <<IDATs/binary, Data/binary>>, Footer, Meta);

%% iend marks the end. uncompress the combined idats
parse_chunks(<<Length:32, "IEND", Data:Length/binary, CRC:32, _Rest/binary>>, Headers, IDATs, _Footer, Meta) ->
    FooterChunk = <<Length:32, "IEND", Data/binary, CRC:32>>,
    RawPixels = zlib:uncompress(IDATs),
    {Meta, Headers, RawPixels, FooterChunk};

%% match other chunks and append to header envelope
parse_chunks(<<Length:32, Type:4/binary, Data:Length/binary, CRC:32, Rest/binary>>, Headers, IDATs, Footer, Meta) ->
    NewHeaders = <<Headers/binary, Length:32, Type/binary, Data/binary, CRC:32>>,
    parse_chunks(Rest, NewHeaders, IDATs, Footer, Meta);
parse_chunks(BadChunk, _Headers, _IDATs, _Footer, _Meta) ->
    erlang:display({~"TRUNCATED OR BAD CHUNK", BadChunk}),
    erlang:error(malformed_chunk).

%% --- DEFILTERING LOGIC ---

defilter_image(PhotoPixels, Width, BitDepth, ColorType, Bpp) ->
    Channels = case ColorType of
        0 -> 1; 2 -> 3; 3 -> 1; 4 -> 2; 6 -> 4 
    end,
    
    BitsPerRow = Width * Channels * BitDepth,
    PhotoRowBytes = (BitsPerRow + 7) div 8,
    
    %% Initialize previous row with zeros for the first row
    PrevRow = <<0:(PhotoRowBytes*8)>>,
    
    %% Extract raw pixels into a flat binary
    extract_raw(PhotoRowBytes, Bpp, PhotoPixels, PrevRow, <<>>).

extract_raw(PhotoRowBytes, Bpp, PhotoPixels, PrevRow, Acc) ->
    %% Now safely slice the binary using the bound variable
    case PhotoPixels of
        <<Filter:8, Row:PhotoRowBytes/binary, Rest/binary>> ->
            RawRow = defilter(Filter, Row, PrevRow, Bpp),
            extract_raw(PhotoRowBytes, Bpp, Rest, RawRow, <<Acc/binary,RawRow/binary>>);
        <<>> ->
            Acc
    end.
%% --- DEFILTERING LOGIC ---
defilter(0, Row, _PrevRow, _Bpp) -> Row;
defilter(1, Row, _PrevRow, Bpp) -> defilter_sub(Row, Bpp, <<>>);
defilter(2, Row, PrevRow, _Bpp) -> defilter_up(Row, PrevRow, <<>>);
defilter(3, Row, PrevRow, Bpp) -> defilter_avg(Row, PrevRow, Bpp, <<>>);
defilter(4, Row, PrevRow, Bpp) -> defilter_paeth(Row, PrevRow, Bpp, <<>>).

defilter_sub(Row, Bpp, Acc) when byte_size(Acc) < byte_size(Row) ->
    I = byte_size(Acc),
    F = binary:at(Row, I),
    P = if I < Bpp -> 0; true -> binary:at(Acc, I - Bpp) end,
    Raw = (F + P) band 255,
    defilter_sub(Row, Bpp, <<Acc/binary, Raw:8>>);
defilter_sub(_, _, Acc) -> Acc.

defilter_up(Row, PrevRow, Acc) when byte_size(Acc) < byte_size(Row) ->
    I = byte_size(Acc),
    F = binary:at(Row, I),
    U = binary:at(PrevRow, I),
    Raw = (F + U) band 255,
    defilter_up(Row, PrevRow, <<Acc/binary, Raw:8>>);
defilter_up(_, _, Acc) -> Acc.

defilter_avg(Row, PrevRow, Bpp, Acc) when byte_size(Acc) < byte_size(Row) ->
    I = byte_size(Acc),
    F = binary:at(Row, I),
    U = binary:at(PrevRow, I),
    P = if I < Bpp -> 0; true -> binary:at(Acc, I - Bpp) end,
    Raw = (F + (P + U) div 2) band 255,
    defilter_avg(Row, PrevRow, Bpp, <<Acc/binary, Raw:8>>);
defilter_avg(_, _, _, Acc) -> Acc.

defilter_paeth(Row, PrevRow, Bpp, Acc) when byte_size(Acc) < byte_size(Row) ->
    I = byte_size(Acc),
    F = binary:at(Row, I),
    U = binary:at(PrevRow, I),
    P = if I < Bpp -> 0; true -> binary:at(Acc, I - Bpp) end,
    UP = if I < Bpp -> 0; true -> binary:at(PrevRow, I - Bpp) end,
    Raw = (F + paeth_predictor(P, U, UP)) band 255,
    defilter_paeth(Row, PrevRow, Bpp, <<Acc/binary, Raw:8>>);
defilter_paeth(_, _, _, Acc) -> Acc.

paeth_predictor(A, B, C) ->
    P = A + B - C,
    Pa = abs(P - A),
    Pb = abs(P - B),
    Pc = abs(P - C),
    if (Pa =< Pb) and (Pa =< Pc) -> A;
       Pb =< Pc -> B;
       true -> C
    end.
