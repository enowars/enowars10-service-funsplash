-module(png).
-export([parse_png/1]).

build_idat(CompressedPixels) ->
    Length = byte_size(CompressedPixels),
    CRCData = <<"IDAT", CompressedPixels/binary>>,
    CRC = erlang:crc32(CRCData),
    <<Length:32, CRCData/binary, CRC:32>>.

%% Matches the exact 8-byte PNG signature
parse_png(<<137, 80, 78, 71, 13, 10, 26, 10, Rest/binary>>) ->
    Signature = <<137, 80, 78, 71, 13, 10, 26, 10>>,
    parse_chunks(Rest, Signature, <<>>, <<>>, 0).

%% Extract Width from IHDR, keep building the Header Envelope
parse_chunks(<<Length:32, "IHDR", Data:Length/binary, CRC:32, Rest/binary>>, Headers, IDATs, Footer, _Width) ->
    <<W:32, _H:32, _/binary>> = Data,
    NewHeaders = <<Headers/binary, Length:32, "IHDR", Data/binary, CRC:32>>,
    parse_chunks(Rest, NewHeaders, IDATs, Footer, W);

%% Extract IDATs (there can be multiple in large images), combine them
parse_chunks(<<Length:32, "IDAT", Data:Length/binary, CRC:32, Rest/binary>>, Headers, IDATs, Footer, Width) ->
    parse_chunks(Rest, Headers, <<IDATs/binary, Data/binary>>, Footer, Width);

%% IEND marks the end. Uncompress the combined IDATs to get raw pixels.
parse_chunks(<<Length:32, "IEND", Data:Length/binary, CRC:32, _Rest/binary>>, Headers, IDATs, _Footer, Width) ->
    FooterChunk = <<Length:32, "IEND", Data/binary, CRC:32>>,
    RawPixels = zlib:uncompress(IDATs),
    {Width, Headers, RawPixels, FooterChunk};

%% Match any other chunk (PLTE, sRGB, etc.) and append to Header Envelope
parse_chunks(<<Length:32, Type:4/binary, Data:Length/binary, CRC:32, Rest/binary>>, Headers, IDATs, Footer, Width) ->
    NewHeaders = <<Headers/binary, Length:32, Type/binary, Data/binary, CRC:32>>,
    parse_chunks(Rest, NewHeaders, IDATs, Footer, Width).

%% Native C-optimized CRC32 png checksum
crc32(Data) ->
    erlang:crc32(Data).
