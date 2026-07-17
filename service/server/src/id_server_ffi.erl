-module(id_server_ffi).
-export([init/0, generate/0]).

init() ->
    rand:seed(exsss, {42, 43, 44}),
    ok.

generate() ->
    rand:bytes(9).
