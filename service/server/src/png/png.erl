-module(png).
-export([parse_png/1, build_idat/1]).

%% build_idat(CompressedPixels) ->
%%     Length = byte_size(CompressedPixels),
%%     CRCData = <<"IDAT", CompressedPixels/binary>>,
%%     CRC = erlang:crc32(CRCData),
%%     <<Length:32, CRCData/binary, CRC:32>>.

build_idat(CompressedIoList) ->
    %% 1. Force a flat binary. This safely resolves iolists, BitBuilders, 
    %% and ensures byte-alignment before we try to measure or append it.
    %% CompressedPixels = iolist_to_binary(CompressedIoList),
    
    Length = byte_size(CompressedIoList),
    
    %% 2. erlang:crc32/1 natively accepts iodata (lists). 
    %% We can compute the CRC without allocating a massive CRCData binary.
    CRC = erlang:crc32(["IDAT", CompressedIoList]),
    
    %% 3. Safely pack the final chunk.
    [<<Length:32, "IDAT">>, CompressedIoList, <<CRC:32>>].

%% uncompresses
parse_png(<<137, 80, 78, 71, 13, 10, 26, 10, Rest/binary>>) ->
    Signature = <<137, 80, 78, 71, 13, 10, 26, 10>>,
    parse_chunks(Rest, Signature, <<>>, <<>>, {});
parse_png(BadBinary) ->
    erlang:display({<<"BAD PNG SIGNATURE">>, BadBinary}),
    erlang:error(invalid_signature).


%% extract width from ihdr, keep building the header envelope
parse_chunks(<<Length:32, "IHDR", Data:Length/binary, CRC:32, Rest/binary>>, Headers, IDATs, Footer, _Meta) ->
    <<W:32, H:32, BitDepth:8, ColorType:8, _/binary>> = Data,
    NewHeaders = <<Headers/binary, Length:32, "IHDR", Data/binary, CRC:32>>,
    parse_chunks(Rest, NewHeaders, IDATs, Footer, {W, H, BitDepth, ColorType});

%% extract idats and combine them
parse_chunks(<<Length:32, "IDAT", Data:Length/binary, CRC:32, Rest/binary>>, Headers, IDATs, Footer, Meta) ->
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
    erlang:display({<<"TRUNCATED OR BAD CHUNK">>, BadChunk}),
    erlang:error(malformed_chunk).


%% native c-optimized crc32 png checksum
crc32(Data) ->
    erlang:crc32(Data).
