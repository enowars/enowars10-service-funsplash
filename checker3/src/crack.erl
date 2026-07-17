#!/usr/bin/env escript
%% Usage: crack.erl <pid1>
%% Server seeds rand:seed(exsss, {42,43,44}). We advance incrementally,
%% saving states. When we find a match, restore saved states for reverse
%% predictions.

-module(crack).
-export([main/1]).

-define(BASE, 42).

main([Observed]) ->
    _ = rand:seed(exsss, {?BASE, ?BASE + 1, ?BASE + 2}),
    find_offset(Observed, 0, []).

find_offset(Observed, Offset, History) ->
    State = rand:export_seed(),
    Bytes = rand:bytes(9),
    Pid = encode_pid(Bytes),
    case binary_to_list(Pid) =:= Observed of
        true ->
            print_reverse(History, 2000);
        false ->
            find_offset(Observed, Offset + 1, [State | History])
    end.

print_reverse(History, N) ->
    print_reverse(History, N, []).

print_reverse([], _K, Acc) ->
    lists:foreach(fun(P) -> io:format("~s~n", [P]) end, lists:reverse(Acc));
print_reverse([State | Rest], K, Acc) when K > 0 ->
    _ = rand:seed(State),
    Bytes = rand:bytes(9),
    Pid = encode_pid(Bytes),
    print_reverse(Rest, K - 1, [Pid | Acc]);
print_reverse(_History, 0, Acc) ->
    lists:foreach(fun(P) -> io:format("~s~n", [P]) end, lists:reverse(Acc)).

encode_pid(Bytes) ->
    Encoded = base64:encode(Bytes, #{mode => urlsafe, padding => false}),
    string:slice(Encoded, 1, 11).
