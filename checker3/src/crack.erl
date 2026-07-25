-module(crack).
-export([main/1]).

-define(MAX_T, 32).
-define(MAX_OFFSET, 200000).
-define(NUM_WORKERS, 16).
-define(CACHE_FILE, "/tmp/crack_seed").

main([ObsStr]) ->
    Obs = decode_observed(ObsStr),
    {T, _StartOff} = case file:read_file(?CACHE_FILE) of
			 {ok, Bin} ->
			     [TStr, OffStr] = string:tokens(binary_to_list(Bin), " "),
			     {list_to_integer(TStr), list_to_integer(OffStr)};
			 _ -> {not_cached, 0}
		     end,
    case T of
        not_cached ->
            case parallel_search(Obs) of
                {ok, FoundT, Offset} ->
                    file:write_file(?CACHE_FILE,
				    integer_to_list(FoundT) ++ " " ++ integer_to_list(Offset)),
                    output_predictions(FoundT, Offset);
                not_found ->
                    io:format("not_found~n")
            end;
        _ ->
            _ = rand:seed(exsss, {T, T + 1, T + 2}),
            case compare_9(rand:bytes(9), Obs) of
                true ->
                    Offset = find_offset_at(T, Obs, 1),
                    file:write_file(?CACHE_FILE,
				    integer_to_list(T) ++ " " ++ integer_to_list(Offset)),
                    output_predictions(T, Offset);
                false ->
                    file:delete(?CACHE_FILE),
                    case parallel_search(Obs) of
                        {ok, FoundT, Off} ->
                            file:write_file(?CACHE_FILE,
					    integer_to_list(FoundT) ++ " " ++ integer_to_list(Off)),
                            output_predictions(FoundT, Off);
                        not_found ->
                            io:format("not_found~n")
                    end
            end
    end.

find_offset_at(T, Obs, StartOff) ->
    _ = rand:seed(exsss, {T, T + 1, T + 2}),
    find_offset_at(T, Obs, 0, StartOff).

find_offset_at(_T, _Obs, Offset, _StartOff) when Offset < _StartOff ->
    _ = rand:bytes(9),
    find_offset_at(_T, _Obs, Offset + 1, _StartOff);
find_offset_at(_T, Obs, Offset, _StartOff) ->
    case compare_9(rand:bytes(9), Obs) of
        true -> Offset;
        _    -> find_offset_at(_T, Obs, Offset + 1, Offset)
    end.

output_predictions(T, Offset) ->
    History = build_history(T, Offset),
    lists:foreach(
      fun(State) ->
	      _ = rand:seed(State),
	      io:format("~s~n", [encode(rand:bytes(9))])
      end,
      History
     ).

%% decode

decode_observed(PidStr) ->
    decode_observed(PidStr, 0).

decode_observed(PidStr, Guess) when Guess < 64 ->
    Padded = binary:list_to_bin([base64url_char(Guess)] ++ PidStr),
    Std = urlsafe_to_standard(Padded),
    Raw = base64:decode(Std),
    case binary_to_list(encode(Raw)) =:= PidStr of
        true  -> Raw;
        false -> decode_observed(PidStr, Guess + 1)
    end.

urlsafe_to_standard(Bin) ->
    << <<case C of $- -> $+; $_ -> $/; _ -> C end>> || <<C:8>> <= Bin >>.

base64url_char(N) when N < 26 -> N + $A;
base64url_char(N) when N < 52 -> N - 26 + $a;
base64url_char(N) when N < 62 -> N - 52 + $0;
base64url_char(62) -> $-;
base64url_char(63) -> $_.

%% search

parallel_search(Obs) ->
    Main = self(),
    Chunk = ceil(?MAX_T / ?NUM_WORKERS),
    Workers = [
	       spawn(fun() -> worker(Obs, Start * Chunk, Chunk, Main) end)
	       || Start <- lists:seq(0, ?NUM_WORKERS - 1)
	      ],
    Result = wait_first(Workers),
    [exit(W, kill) || W <- Workers],
    Result.

worker(Obs, TStart, Chunk, Main) ->
    TEnd = min(TStart + Chunk - 1, ?MAX_T),
    worker_search(Obs, TStart, TEnd, Main).

worker_search(Obs, T, TEnd, Main) when T =< TEnd ->
    _ = rand:seed(exsss, {T, T + 1, T + 2}),
    case scan(Obs, 0) of
        {ok, Offset} -> Main ! {found, T, Offset};
        not_found     -> worker_search(Obs, T + 1, TEnd, Main)
    end;
worker_search(_Obs, _T, _TEnd, _Main) -> ok.

scan(Obs, Offset) ->
    case compare_9(rand:bytes(9), Obs) of
        true  -> {ok, Offset};
        false -> advance(Obs, Offset + 1)
    end.

compare_9(Bytes, Ref) ->
    <<B0:8, Rest/bits>> = Bytes,
    <<R0:8, RefRest/bits>> = Ref,
    (B0 band 2#00000011) =:= (R0 band 2#00000011) andalso Rest =:= RefRest.

advance(_Obs, Offset) when Offset >= ?MAX_OFFSET -> not_found;
advance(Obs, Offset) -> scan(Obs, Offset).

wait_first(Workers) ->
    receive
        {found, T, Offset} -> {ok, T, Offset}
    after 50 ->
	    case lists:any(fun erlang:is_process_alive/1, Workers) of
		true  -> wait_first(Workers);
		false -> not_found
	    end
    end.

%% history

build_history(T, Offset) ->
    _ = rand:seed(exsss, {T, T + 1, T + 2}),
    build_history(T, Offset, 0, []).

build_history(_T, Offset, I, Acc) when I < Offset ->
    State = rand:export_seed(),
    _ = rand:bytes(9),
    build_history(_T, Offset, I + 1, [State | Acc]);
build_history(_T, _Offset, _I, Acc) ->
    lists:reverse(Acc).

%% encode

encode(Bytes) ->
    Encoded = base64:encode(Bytes, #{mode => urlsafe, padding => false}),
    string:slice(Encoded, 1, 11).
