-module(censor).
-export([apply_mask/5]).

apply_mask(PhotoPixels, MaskPixels, Width, BitDepth, ColorType) ->
    Channels = case ColorType of
		   0 -> 1; 2 -> 3; 3 -> 1; 4 -> 2; 6 -> 4
	       end,

    BitsPerRow = Width * Channels * BitDepth,
    PhotoRowBytes = (BitsPerRow + 7) div 8,
    MaskRowBytes = Width * 4,
    BlackMaskRow = binary:copy(<<0, 0, 0, 255>>, PhotoRowBytes div 4),

    process_rows(PhotoRowBytes, MaskRowBytes, BitDepth, ColorType, BlackMaskRow, PhotoPixels, MaskPixels, 0, []).

process_rows(_PRB, _MRB, _Depth, _Type, _BlackMaskRow, <<>>, _Mask, _OffsetMask, Acc) ->
    lists:reverse(Acc);
process_rows(PhotoRowBytes, MaskRowBytes, BitDepth, ColorType, BlackMaskRow, RawPhoto, Mask, OffsetMask, Acc) ->
    <<RawRow:PhotoRowBytes/binary, PhotoRest/binary>> = RawPhoto,
    MaskRow = binary_part(Mask, OffsetMask + 1, MaskRowBytes),
    NextOffsetMask = OffsetMask + MaskRowBytes + 1,
    case MaskRow =:= BlackMaskRow of
	true ->
            process_rows(PhotoRowBytes, MaskRowBytes, BitDepth, ColorType, BlackMaskRow, PhotoRest, Mask, NextOffsetMask, [[0, BlackMaskRow] | Acc]);
	false ->
            case is_transparent_censored(MaskRow) of
                true ->
                    process_rows(PhotoRowBytes, MaskRowBytes, BitDepth, ColorType, BlackMaskRow, PhotoRest, Mask, NextOffsetMask, [[0, RawRow] | Acc]);
                false ->
                    NewRow = if
				 BitDepth =:= 8, ColorType =:= 6 -> merge_rgba(RawRow, MaskRow, 0, <<>>);
				 BitDepth =:= 8, ColorType =:= 2 -> merge_rgb(RawRow, MaskRow, 0, <<>>);
				 BitDepth =:= 8, ColorType =:= 0 -> merge_gray(RawRow, MaskRow, 0, <<>>);
				 BitDepth =:= 8, ColorType =:= 3 -> merge_gray(RawRow, MaskRow, 0, <<>>);
				 BitDepth =:= 8, ColorType =:= 4 -> merge_gray_alpha(RawRow, MaskRow, 0, <<>>);
				 BitDepth =:= 1 -> merge_bw(RawRow, MaskRow, 0, <<>>);
				 true -> RawRow
			     end,
                    process_rows(PhotoRowBytes, MaskRowBytes, BitDepth, ColorType, BlackMaskRow, PhotoRest, Mask, NextOffsetMask, [[0, NewRow] | Acc])
            end
    end.

is_transparent_censored(<<_:3/binary, 0:8, _:3/binary, 0:8, _:3/binary, 0:8, _:3/binary, 0:8,
                          _:3/binary, 0:8, _:3/binary, 0:8, _:3/binary, 0:8, _:3/binary, 0:8, Rest/binary>>) ->
    is_transparent_censored(Rest);
is_transparent_censored(<<_:3/binary, 0:8, Rest/binary>>) ->
    is_transparent_censored(Rest);
is_transparent_censored(<<>>) -> true;
is_transparent_censored(_) -> false.

%% --- 1-BIT MASKING ---
%% --- 1-BIT MASKING ---
merge_bw(<<>>, _Mask, _Offset, Acc) -> Acc;
merge_bw(<<P:1/binary, PRest/binary>>, Mask, Offset, Acc) when byte_size(Mask) - Offset >= 32 ->
    case binary_part(Mask, Offset, 32) of
        <<_:24, 0:8, _:24, 0:8, _:24, 0:8, _:24, 0:8,
          _:24, 0:8, _:24, 0:8, _:24, 0:8, _:24, 0:8>> ->
            merge_bw(PRest, Mask, Offset+32, <<Acc/binary, P/binary>>);
        <<_:24, 255:8, _:24, 255:8, _:24, 255:8, _:24, 255:8,
          _:24, 255:8, _:24, 255:8, _:24, 255:8, _:24, 255:8>> ->
            merge_bw(PRest, Mask, Offset+32, <<Acc/binary, 0:8>>);
        <<_R1:24, M1A:8, _R2:24, M2A:8, _R3:24, M3A:8, _R4:24, M4A:8,
          _R5:24, M5A:8, _R6:24, M6A:8, _R7:24, M7A:8, _R8:24, M8A:8>> ->
            <<PhotoByte:8>> = P,
            KeepMask = ((bnot M1A) band 128) bor
                (((bnot M2A) band 128) bsr 1) bor
                (((bnot M3A) band 128) bsr 2) bor
                (((bnot M4A) band 128) bsr 3) bor
                (((bnot M5A) band 128) bsr 4) bor
                (((bnot M6A) band 128) bsr 5) bor
                (((bnot M7A) band 128) bsr 6) bor
                (((bnot M8A) band 128) bsr 7),
            NewByte = PhotoByte band KeepMask,
            merge_bw(PRest, Mask, Offset+32, <<Acc/binary, NewByte:8>>)
    end;
merge_bw(<<LastPhotoByte:8>>, Mask, Offset, Acc) ->
    TrailingMask = binary_part(Mask, Offset, byte_size(Mask) - Offset),
    MissingBytes = 32 - byte_size(TrailingMask),
    PaddedMask = <<TrailingMask/binary, 0:(MissingBytes*8)>>,
    merge_bw(<<LastPhotoByte:8>>, PaddedMask, 0, Acc).

%% --- 8-BIT MERGING LOGIC ---
merge_rgba(<<>>, _Mask, _Offset, Acc) -> Acc;
merge_rgba(<<P:32/binary, PRest/binary>>, Mask, Offset, Acc) when byte_size(Mask) - Offset >= 32 ->
    case binary_part(Mask, Offset, 32) of
        <<_:24, 0:8, _:24, 0:8, _:24, 0:8, _:24, 0:8,
          _:24, 0:8, _:24, 0:8, _:24, 0:8, _:24, 0:8>> ->
            merge_rgba(PRest, Mask, Offset+32, <<Acc/binary, P/binary>>);
        <<M1:3/binary, 255:8, M2:3/binary, 255:8, M3:3/binary, 255:8, M4:3/binary, 255:8,
          M5:3/binary, 255:8, M6:3/binary, 255:8, M7:3/binary, 255:8, M8:3/binary, 255:8>> ->
            <<_:24, PA1:8, _:24, PA2:8, _:24, PA3:8, _:24, PA4:8,
              _:24, PA5:8, _:24, PA6:8, _:24, PA7:8, _:24, PA8:8>> = P,
            merge_rgba(PRest, Mask, Offset+32, <<Acc/binary, M1/binary, PA1:8, M2/binary, PA2:8, M3/binary, PA3:8, M4/binary, PA4:8,
                               M5/binary, PA5:8, M6/binary, PA6:8, M7/binary, PA7:8, M8/binary, PA8:8>>);
        _ ->
            Acc2 = merge_rgba_mixed(P, Mask, Offset, Acc),
            merge_rgba(PRest, Mask, Offset+32, Acc2)
    end;
merge_rgba(<<PR:8, PG:8, PB:8, PA:8, PRest/binary>>, Mask, Offset, Acc) ->
    MR = binary:at(Mask, Offset), MG = binary:at(Mask, Offset+1), MB = binary:at(Mask, Offset+2), MA = binary:at(Mask, Offset+3),
    if MA > 127 -> merge_rgba(PRest, Mask, Offset+4, <<Acc/binary, MR:8, MG:8, MB:8, PA:8>>);
       true     -> merge_rgba(PRest, Mask, Offset+4, <<Acc/binary, PR:8, PG:8, PB:8, PA:8>>)
    end.

merge_rgba_mixed(<<>>, _Mask, _Offset, Acc) -> Acc;
merge_rgba_mixed(<<PR:8, PG:8, PB:8, PA:8, PRest/binary>>, Mask, Offset, Acc) ->
    MR = binary:at(Mask, Offset), MG = binary:at(Mask, Offset+1), MB = binary:at(Mask, Offset+2), MA = binary:at(Mask, Offset+3),
    if MA > 127 -> merge_rgba_mixed(PRest, Mask, Offset+4, <<Acc/binary, MR:8, MG:8, MB:8, PA:8>>);
       true     -> merge_rgba_mixed(PRest, Mask, Offset+4, <<Acc/binary, PR:8, PG:8, PB:8, PA:8>>)
    end.

merge_rgb(<<>>, _Mask, _Offset, Acc) -> Acc;
merge_rgb(<<P:24/binary, PRest/binary>>, Mask, Offset, Acc) when byte_size(Mask) - Offset >= 32 ->
    case binary_part(Mask, Offset, 32) of
        <<_:24, 0:8, _:24, 0:8, _:24, 0:8, _:24, 0:8,
          _:24, 0:8, _:24, 0:8, _:24, 0:8, _:24, 0:8>> ->
            merge_rgb(PRest, Mask, Offset+32, <<Acc/binary, P/binary>>);
        <<M1:3/binary, 255:8, M2:3/binary, 255:8, M3:3/binary, 255:8, M4:3/binary, 255:8,
          M5:3/binary, 255:8, M6:3/binary, 255:8, M7:3/binary, 255:8, M8:3/binary, 255:8>> ->
            merge_rgb(PRest, Mask, Offset+32, <<Acc/binary, M1/binary, M2/binary, M3/binary, M4/binary,
                              M5/binary, M6/binary, M7/binary, M8/binary>>);
        _ ->
            Acc2 = merge_rgb_mixed(P, Mask, Offset, Acc),
            merge_rgb(PRest, Mask, Offset+32, Acc2)
    end;
merge_rgb(<<PR:8, PG:8, PB:8, PRest/binary>>, Mask, Offset, Acc) ->
    MR = binary:at(Mask, Offset), MG = binary:at(Mask, Offset+1), MB = binary:at(Mask, Offset+2), MA = binary:at(Mask, Offset+3),
    if MA > 127 -> merge_rgb(PRest, Mask, Offset+4, <<Acc/binary, MR:8, MG:8, MB:8>>);
       true     -> merge_rgb(PRest, Mask, Offset+4, <<Acc/binary, PR:8, PG:8, PB:8>>)
    end.

merge_rgb_mixed(<<>>, _Mask, _Offset, Acc) -> Acc;
merge_rgb_mixed(<<PR:8, PG:8, PB:8, PRest/binary>>, Mask, Offset, Acc) ->
    MR = binary:at(Mask, Offset), MG = binary:at(Mask, Offset+1), MB = binary:at(Mask, Offset+2), MA = binary:at(Mask, Offset+3),
    if MA > 127 -> merge_rgb_mixed(PRest, Mask, Offset+4, <<Acc/binary, MR:8, MG:8, MB:8>>);
       true     -> merge_rgb_mixed(PRest, Mask, Offset+4, <<Acc/binary, PR:8, PG:8, PB:8>>)
    end.

merge_gray(<<>>, _Mask, _Offset, Acc) -> Acc;
merge_gray(<<P:8/binary, PRest/binary>>, Mask, Offset, Acc) when byte_size(Mask) - Offset >= 32 ->
    case binary_part(Mask, Offset, 32) of
        <<_:24, 0:8, _:24, 0:8, _:24, 0:8, _:24, 0:8,
          _:24, 0:8, _:24, 0:8, _:24, 0:8, _:24, 0:8>> ->
            merge_gray(PRest, Mask, Offset+32, <<Acc/binary, P/binary>>);
        <<_:24, 255:8, _:24, 255:8, _:24, 255:8, _:24, 255:8,
          _:24, 255:8, _:24, 255:8, _:24, 255:8, _:24, 255:8>> ->
            merge_gray(PRest, Mask, Offset+32, <<Acc/binary, 0:64>>);
        _ ->
            Acc2 = merge_gray_mixed(P, Mask, Offset, Acc),
            merge_gray(PRest, Mask, Offset+32, Acc2)
    end;
merge_gray(<<PGray:8, PRest/binary>>, Mask, Offset, Acc) ->
    MA = binary:at(Mask, Offset+3),
    if MA > 127 -> merge_gray(PRest, Mask, Offset+4, <<Acc/binary, 0:8>>);
       true     -> merge_gray(PRest, Mask, Offset+4, <<Acc/binary, PGray:8>>)
    end.

merge_gray_mixed(<<>>, _Mask, _Offset, Acc) -> Acc;
merge_gray_mixed(<<PGray:8, PRest/binary>>, Mask, Offset, Acc) ->
    MA = binary:at(Mask, Offset+3),
    if MA > 127 -> merge_gray_mixed(PRest, Mask, Offset+4, <<Acc/binary, 0:8>>);
       true     -> merge_gray_mixed(PRest, Mask, Offset+4, <<Acc/binary, PGray:8>>)
    end.

merge_gray_alpha(<<>>, _Mask, _Offset, Acc) -> Acc;
merge_gray_alpha(<<P:16/binary, PRest/binary>>, Mask, Offset, Acc) when byte_size(Mask) - Offset >= 32 ->
    case binary_part(Mask, Offset, 32) of
        <<_:24, 0:8, _:24, 0:8, _:24, 0:8, _:24, 0:8,
          _:24, 0:8, _:24, 0:8, _:24, 0:8, _:24, 0:8>> ->
            merge_gray_alpha(PRest, Mask, Offset+32, <<Acc/binary, P/binary>>);
        <<_:24, 255:8, _:24, 255:8, _:24, 255:8, _:24, 255:8,
          _:24, 255:8, _:24, 255:8, _:24, 255:8, _:24, 255:8>> ->
            <<_:8, PA1:8, _:8, PA2:8, _:8, PA3:8, _:8, PA4:8,
              _:8, PA5:8, _:8, PA6:8, _:8, PA7:8, _:8, PA8:8>> = P,
            merge_gray_alpha(PRest, Mask, Offset+32, <<Acc/binary, 0:8, PA1:8, 0:8, PA2:8, 0:8, PA3:8, 0:8, PA4:8,
                                     0:8, PA5:8, 0:8, PA6:8, 0:8, PA7:8, 0:8, PA8:8>>);
        _ ->
            Acc2 = merge_gray_alpha_mixed(P, Mask, Offset, Acc),
            merge_gray_alpha(PRest, Mask, Offset+32, Acc2)
    end;
merge_gray_alpha(<<PGray:8, PA:8, PRest/binary>>, Mask, Offset, Acc) ->
    MA = binary:at(Mask, Offset+3),
    if MA > 127 -> merge_gray_alpha(PRest, Mask, Offset+4, <<Acc/binary, 0:8, PA:8>>);
       true     -> merge_gray_alpha(PRest, Mask, Offset+4, <<Acc/binary, PGray:8, PA:8>>)
    end.

merge_gray_alpha_mixed(<<>>, _Mask, _Offset, Acc) -> Acc;
merge_gray_alpha_mixed(<<PGray:8, PA:8, PRest/binary>>, Mask, Offset, Acc) ->
    MA = binary:at(Mask, Offset+3),
    if MA > 127 -> merge_gray_alpha_mixed(PRest, Mask, Offset+4, <<Acc/binary, 0:8, PA:8>>);
       true     -> merge_gray_alpha_mixed(PRest, Mask, Offset+4, <<Acc/binary, PGray:8, PA:8>>)
    end.
