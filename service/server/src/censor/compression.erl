-module(compression).
-export([compress/1, init_compressor/0, close_compressor/1, compress_stream/2]).

%% zlib Level 1 for maximum speed
compress(Data) ->
    Z = zlib:open(),
    ok = zlib:deflateInit(Z, 1),
    Compressed = zlib:deflate(Z, Data, finish),
    ok = zlib:close(Z),
    iolist_to_binary(Compressed).

%% for socket
init_compressor() ->
    Z = zlib:open(),
    ok = zlib:deflateInit(Z, 1),
    Z.

compress_stream(Z, Data) ->
    zlib:deflate(Z, Data, full).

close_compressor(Z) ->
    zlib:deflateend(Z),
    zlib:close(Z).
