-module(id_server_ffi).
-export([init/0]).

init() ->
    T = erlang:phash2({erlang:monotonic_time(nanosecond), erlang:unique_integer([monotonic])}, 32),
    rand:seed(exsss, {T, T + 1, T + 2}),
    ok.
