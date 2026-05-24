-module(test_png).
-export([run/0]).

run() ->
    {ok, Bin} = file:read_file("test.png"),
    io:format("Read ~p bytes~n", [byte_size(Bin)]),
    try png:parse_png(Bin) of
        {Width, Headers, RawPixels, FooterChunk} ->
            io:format("Success! Width: ~p, Headers: ~p, Pixels: ~p, Footer: ~p~n", [Width, byte_size(Headers), byte_size(RawPixels), byte_size(FooterChunk)])
    catch
        Class:Reason:Stacktrace ->
            io:format("Crash: ~p:~p~nStacktrace: ~p~n", [Class, Reason, Stacktrace])
    end.
