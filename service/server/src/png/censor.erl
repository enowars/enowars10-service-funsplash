-module(censor).
-export([apply_mask/3]).

%% bitwise and the 841 bytes, then chunk into 29-byte rows with a 0x00 filter byte
apply_mask(Target, Mask, Width) when is_integer(Width), Width > 0 ->
    Redacted = << <<(T band M)>> || <<T>> <= Target && <<M>> <= Mask >>,
    add_filters(Redacted, Width, []);
apply_mask(_, _, _) ->
    [].

%% TODO: check if length is bytes, not bits
add_filters(Data, Width, Acc) ->
    case Data of
	<<Row:Width/binary, Rest/binary>> ->
	    add_filters(Rest, Width, [[<<0:8>>, Row] | Acc]);
	<<>> ->
	    lists:reverse(Acc);
	<<Leftover/binary>> ->
	    lists:reverse([[<<0:8>>, Leftover] | Acc])
   end.
