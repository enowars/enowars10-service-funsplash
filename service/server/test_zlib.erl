-module(test_zlib).
-export([run/0]).

run() ->
    Z = zlib:open(),
    ok = zlib:deflateInit(Z, 1),
    _Data = zlib:deflate(Z, <<"test data">>, full),
    try
        zlib:deflateEnd(Z),
        io:format("deflateEnd success~n")
    catch
        Class:Reason -> io:format("Crash 1: ~p:~p~n", [Class, Reason])
    end,
    try
        zlib:close(Z),
        io:format("close success~n")
    catch
        Class2:Reason2 -> io:format("Crash 2: ~p:~p~n", [Class2, Reason2])
    end.
