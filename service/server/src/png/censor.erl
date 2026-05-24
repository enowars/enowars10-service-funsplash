-module(censor).
-export([apply_mask/5]).

apply_mask(PhotoPixels, MaskPixels, Width, BitDepth, ColorType) ->
    Channels = case ColorType of
        0 -> 1;
        2 -> 3;
        3 -> 1;
        4 -> 2;
        6 -> 4 
    end,
    
    BitsPerRow = Width * Channels * BitDepth,
    PhotoRowBytes = (BitsPerRow + 7) div 8,
    MaskRowBytes = Width * 4,
    Bpp = lists:max([1, (Channels * BitDepth) div 8]),
    
    %% Initialize previous row with zeros for the first row's defiltering
    PrevRow = <<0:(PhotoRowBytes*8)>>,
    
    process_rows(PhotoRowBytes, MaskRowBytes, Width, BitDepth, ColorType, Bpp,
                 PhotoPixels, MaskPixels, 0, [], PrevRow).

process_rows(PhotoRowBytes, MaskRowBytes, Width, BitDepth, ColorType, Bpp,
             Photo, Mask, Y, Acc, PrevRawRow) ->
    case {Photo, Mask} of
        {<<Filter:8, PhotoRow:PhotoRowBytes/binary, PhotoRest/binary>>,
         <<_MaskFilter:8, MaskRow:MaskRowBytes/binary, MaskRest/binary>>} ->
            
            %% 1. Defilter the incoming row to get raw pixels
            RawRow = defilter(Filter, PhotoRow, PrevRawRow, Bpp),
            
            %% 2. Apply the mask to the raw pixels
            NewRawRow = if
                BitDepth =:= 8, ColorType =:= 6 -> merge_rgba(RawRow, MaskRow, <<>>);
                BitDepth =:= 8, ColorType =:= 2 -> merge_rgb(RawRow, MaskRow, <<>>);
                BitDepth =:= 8, ColorType =:= 0 -> merge_gray(RawRow, MaskRow, <<>>);
                BitDepth =:= 8, ColorType =:= 3 -> merge_gray(RawRow, MaskRow, <<>>);
                BitDepth =:= 8, ColorType =:= 4 -> merge_gray_alpha(RawRow, MaskRow, <<>>);
                BitDepth =:= 1 -> merge_bw(RawRow, MaskRow);
                true -> RawRow 
            end,
            
            %% 3. Output with Filter 0 (None) and recurse, using the NEW raw row for next row's defiltering
            process_rows(PhotoRowBytes, MaskRowBytes, Width, BitDepth, ColorType, Bpp,
                         PhotoRest, MaskRest, Y + 1, [[0, NewRawRow] | Acc], RawRow);
        _ ->
            lists:reverse(Acc)
    end.

%% --- DEFILTERING LOGIC ---
defilter(0, Row, _PrevRow, _Bpp) -> Row;
defilter(1, Row, _PrevRow, Bpp) -> defilter_sub(Row, Bpp, <<>>);
defilter(2, Row, PrevRow, _Bpp) -> defilter_up(Row, PrevRow, <<>>);
defilter(3, Row, PrevRow, Bpp) -> defilter_avg(Row, PrevRow, Bpp, <<>>);
defilter(4, Row, PrevRow, Bpp) -> defilter_paeth(Row, PrevRow, Bpp, <<>>).

defilter_sub(Row, Bpp, Acc) when byte_size(Acc) < byte_size(Row) ->
    I = byte_size(Acc),
    F = binary:at(Row, I),
    P = if I < Bpp -> 0; true -> binary:at(Acc, I - Bpp) end,
    Raw = (F + P) band 255,
    defilter_sub(Row, Bpp, <<Acc/binary, Raw:8>>);
defilter_sub(_, _, Acc) -> Acc.

defilter_up(Row, PrevRow, Acc) when byte_size(Acc) < byte_size(Row) ->
    I = byte_size(Acc),
    F = binary:at(Row, I),
    U = binary:at(PrevRow, I),
    Raw = (F + U) band 255,
    defilter_up(Row, PrevRow, <<Acc/binary, Raw:8>>);
defilter_up(_, _, Acc) -> Acc.

defilter_avg(Row, PrevRow, Bpp, Acc) when byte_size(Acc) < byte_size(Row) ->
    I = byte_size(Acc),
    F = binary:at(Row, I),
    U = binary:at(PrevRow, I),
    P = if I < Bpp -> 0; true -> binary:at(Acc, I - Bpp) end,
    Raw = (F + (P + U) div 2) band 255,
    defilter_avg(Row, PrevRow, Bpp, <<Acc/binary, Raw:8>>);
defilter_avg(_, _, _, Acc) -> Acc.

defilter_paeth(Row, PrevRow, Bpp, Acc) when byte_size(Acc) < byte_size(Row) ->
    I = byte_size(Acc),
    F = binary:at(Row, I),
    U = binary:at(PrevRow, I),
    P = if I < Bpp -> 0; true -> binary:at(Acc, I - Bpp) end,
    UP = if I < Bpp -> 0; true -> binary:at(PrevRow, I - Bpp) end,
    Raw = (F + paeth_predictor(P, U, UP)) band 255,
    defilter_paeth(Row, PrevRow, Bpp, <<Acc/binary, Raw:8>>);
defilter_paeth(_, _, _, Acc) -> Acc.

paeth_predictor(A, B, C) ->
    P = A + B - C,
    Pa = abs(P - A),
    Pb = abs(P - B),
    Pc = abs(P - C),
    if (Pa =< Pb) and (Pa =< Pc) -> A;
       Pb =< Pc -> B;
       true -> C
    end.

%% --- 1-BIT MASKING ---
merge_bw(<<>>, _Mask) -> <<>>;
merge_bw(<<PhotoByte:8, PRest/binary>>,
           <<_R1:24, M1A:8, _R2:24, M2A:8, _R3:24, M3A:8, _R4:24, M4A:8,
             _R5:24, M5A:8, _R6:24, M6A:8, _R7:24, M7A:8, _R8:24, M8A:8, MRest/binary>>) ->
    
    B1 = if M1A > 127 -> 0; true -> (PhotoByte band 128) end,
    B2 = if M2A > 127 -> 0; true -> (PhotoByte band 64) end,
    B3 = if M3A > 127 -> 0; true -> (PhotoByte band 32) end,
    B4 = if M4A > 127 -> 0; true -> (PhotoByte band 16) end,
    B5 = if M5A > 127 -> 0; true -> (PhotoByte band 8) end,
    B6 = if M6A > 127 -> 0; true -> (PhotoByte band 4) end,
    B7 = if M7A > 127 -> 0; true -> (PhotoByte band 2) end,
    B8 = if M8A > 127 -> 0; true -> (PhotoByte band 1) end,
    
    NewByte = B1 bor B2 bor B3 bor B4 bor B5 bor B6 bor B7 bor B8,
    <<NewByte:8, (merge_bw(PRest, MRest))/binary>>;
merge_bw(<<LastPhotoByte:8>>, TrailingMask) ->
    MissingBytes = 32 - byte_size(TrailingMask),
    PaddedMask = <<TrailingMask/binary, 0:(MissingBytes*8)>>,
    merge_bw(<<LastPhotoByte:8>>, PaddedMask).

%% --- 8-BIT MERGING LOGIC ---
merge_rgba(<<>>, <<>>, Acc) -> Acc;
merge_rgba(<<PR:8, PG:8, PB:8, PA:8, PRest/binary>>,
           <<MR:8, MG:8, MB:8, MA:8, MRest/binary>>, Acc) ->
    if MA > 127 -> merge_rgba(PRest, MRest, <<Acc/binary, MR:8, MG:8, MB:8, PA:8>>);
       true     -> merge_rgba(PRest, MRest, <<Acc/binary, PR:8, PG:8, PB:8, PA:8>>)
    end.

merge_rgb(<<>>, <<>>, Acc) -> Acc;
merge_rgb(<<PR:8, PG:8, PB:8, PRest/binary>>,
          <<MR:8, MG:8, MB:8, MA:8, MRest/binary>>, Acc) ->
    if MA > 127 -> merge_rgb(PRest, MRest, <<Acc/binary, MR:8, MG:8, MB:8>>);
       true     -> merge_rgb(PRest, MRest, <<Acc/binary, PR:8, PG:8, PB:8>>)
    end.

merge_gray(<<>>, <<>>, Acc) -> Acc;
merge_gray(<<PGray:8, PRest/binary>>,
           <<_MR:8, _MG:8, _MB:8, MA:8, MRest/binary>>, Acc) ->
    if MA > 127 -> merge_gray(PRest, MRest, <<Acc/binary, 0:8>>);
       true     -> merge_gray(PRest, MRest, <<Acc/binary, PGray:8>>)
    end.

merge_gray_alpha(<<>>, <<>>, Acc) -> Acc;
merge_gray_alpha(<<PGray:8, PA:8, PRest/binary>>,
                 <<_MR:8, _MG:8, _MB:8, MA:8, MRest/binary>>, Acc) ->
    if MA > 127 -> merge_gray_alpha(PRest, MRest, <<Acc/binary, 0:8, PA:8>>);
       true     -> merge_gray_alpha(PRest, MRest, <<Acc/binary, PGray:8, PA:8>>)
    end.
