-module(censor).
-export([apply_mask/5]).

apply_mask(PhotoPixels, MaskPixels, Width, BitDepth, ColorType) ->
    Channels = case ColorType of
		   0 -> 1; 2 -> 3; 3 -> 1; 4 -> 2; 6 -> 4
	       end,

    BitsPerRow = Width * Channels * BitDepth,
    PhotoRowBytes = (BitsPerRow + 7) div 8,
    MaskRowBytes = Width * 4,

    process_rows(PhotoRowBytes, MaskRowBytes, BitDepth, ColorType, PhotoPixels, MaskPixels, []).

process_rows(_PRB, _MRB, _Depth, _Type, <<>>, <<>>, Acc) ->
    lists:reverse(Acc);
process_rows(PhotoRowBytes, MaskRowBytes, BitDepth, ColorType, RawPhoto, Mask, Acc) ->
    <<RawRow:PhotoRowBytes/binary, PhotoRest/binary>> = RawPhoto,
    <<_MaskFilter:8, MaskRow:MaskRowBytes/binary, MaskRest/binary>> = Mask,

    NewRow = if
		 BitDepth =:= 8, ColorType =:= 6 -> merge_rgba(RawRow, MaskRow, <<>>);
		 BitDepth =:= 8, ColorType =:= 2 -> merge_rgb(RawRow, MaskRow, <<>>);
		 BitDepth =:= 8, ColorType =:= 0 -> merge_gray(RawRow, MaskRow, <<>>);
		 BitDepth =:= 8, ColorType =:= 3 -> merge_gray(RawRow, MaskRow, <<>>);
		 BitDepth =:= 8, ColorType =:= 4 -> merge_gray_alpha(RawRow, MaskRow, <<>>);
		 BitDepth =:= 1 -> merge_bw(RawRow, MaskRow, <<>>);
		 true -> RawRow
	     end,

    %% 3. Output with Filter 0 (None) and recurse, using the NEW raw row for next row's defiltering
    process_rows(PhotoRowBytes, MaskRowBytes, BitDepth, ColorType, PhotoRest, MaskRest, [[0, NewRow] | Acc]).

%% --- 1-BIT MASKING ---
merge_bw(<<>>, _Mask, Acc) -> Acc;
merge_bw(<<PhotoByte:8, PRest/binary>>,
	 <<_R1:24, M1A:8, _R2:24, M2A:8, _R3:24, M3A:8, _R4:24, M4A:8,
	   _R5:24, M5A:8, _R6:24, M6A:8, _R7:24, M7A:8, _R8:24, M8A:8, MRest/binary>>, Acc) ->

    KeepMask = ((bnot M1A) band 128) bor
	(((bnot M2A) band 128) bsr 1) bor
	(((bnot M3A) band 128) bsr 2) bor
	(((bnot M4A) band 128) bsr 3) bor
	(((bnot M5A) band 128) bsr 4) bor
	(((bnot M6A) band 128) bsr 5) bor
	(((bnot M7A) band 128) bsr 6) bor
	(((bnot M8A) band 128) bsr 7),

    NewByte = PhotoByte band KeepMask,
    merge_bw(PRest, MRest, <<Acc/binary, NewByte:8>>);
merge_bw(<<LastPhotoByte:8>>, TrailingMask, Acc) ->
    MissingBytes = 32 - byte_size(TrailingMask),
    PaddedMask = <<TrailingMask/binary, 0:(MissingBytes*8)>>,
    merge_bw(<<LastPhotoByte:8>>, PaddedMask, Acc).

%% --- 8-BIT MERGING LOGIC (Optimized with Binary Comprehensions) ---
merge_rgba(PhotoRow, MaskRow, _Acc) ->
    << <<(if MA > 127 -> MR; true -> PR end):8,
         (if MA > 127 -> MG; true -> PG end):8,
         (if MA > 127 -> MB; true -> PB end):8,
         PA:8>> || <<PR:8, PG:8, PB:8, PA:8>> <= PhotoRow,
                   <<MR:8, MG:8, MB:8, MA:8>> <= MaskRow >>.

merge_rgb(PhotoRow, MaskRow, _Acc) ->
    << <<(if MA > 127 -> MR; true -> PR end):8,
         (if MA > 127 -> MG; true -> PG end):8,
         (if MA > 127 -> MB; true -> PB end):8>> || <<PR:8, PG:8, PB:8>> <= PhotoRow,
						    <<MR:8, MG:8, MB:8, MA:8>> <= MaskRow >>.

merge_gray(PhotoRow, MaskRow, _Acc) ->
    << <<(if MA > 127 -> 0; true -> PGray end):8>> || <<PGray:8>> <= PhotoRow,
						      <<_MR:8, _MG:8, _MB:8, MA:8>> <= MaskRow >>.

merge_gray_alpha(PhotoRow, MaskRow, _Acc) ->
    << <<(if MA > 127 -> 0; true -> PGray end):8,
         PA:8>> || <<PGray:8, PA:8>> <= PhotoRow,
                   <<_MR:8, _MG:8, _MB:8, MA:8>> <= MaskRow >>.
