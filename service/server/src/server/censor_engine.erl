-module(censor_engine).
-export([apply_mask_and_filter/2, compress/1, crc32/1]).

%% Bitwise AND the 841 bytes, then chunk into 29-byte rows with a 0x00 filter byte
apply_mask_and_filter(Target, Mask) ->
    Redacted = << <<(T band M)>> || <<T>> <= Target, <<M>> <= Mask >>,
    add_filters(Redacted, <<>>).

add_filters(<<Row:29/binary, Rest/binary>>, Acc) ->
    FilterByte = <<0:8>>, %% Filter: None
    add_filters(Rest, <<Acc/binary, FilterByte/binary, Row/binary>>);
add_filters(<<>>, Acc) ->
    Acc.

%% zlib Level 1 for maximum speed
compress(Data) ->
    Z = zlib:open(),
    ok = zlib:deflateInit(Z, 1),
    Compressed = zlib:deflate(Z, Data, finish),
    ok = zlib:close(Z),
    iolist_to_binary(Compressed).

%% Native C-optimized CRC32
crc32(Data) ->
    erlang:crc32(Data).
