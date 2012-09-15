
( * Proportional font editor )

CREATE D$
    3 , 2 , 18 , 15 , 0 , ,"  Fusion Proportional Font Editor "

CREATE N-B
    2 , 1 , 3 , 20 , ,"  Create new font "

CREATE X-B
    2 , 1 , 22 , 20 , ,"  QUIT "

CREATE S-B
    2 , 1 , 29 , 20 , ,"  Save font "

CREATE L-B
    2 , 1 , 41 , 20 , ,"  Load font "

CREATE <-B
    2 , 1 , 56 , 20 , ,"  <== "

CREATE ^-B
    2 , 1 , 64 , 20 , ,"  ^ "

CREATE _P-BOX
    1 , 10 , 1 , _SOLID A, 1 ,
    1 , 17 , 70 , 22 ,
    7 , D$ A, N-B A, X-B A, S-B A, L-B A, <-B A, ^-B A,

: VAR VARIABLE ; IMMEDIATE

VAR 'FONT
VAR _PNTR
VAR _HANDLE  VAR _WIDTH  VAR _WID
VAR _CHAR    VAR _FLAG

CREATE _PFONT 3072 ALLOT

: NEW-FONT
    8 _PFONT W! ( number of lines in each character )
    _PFONT 2+ 128 8 FILL ( spacing information )
    _PFONT 130 + 2048 0 FILL ( clear out the font before hand )

    _PFONT 130 + _PNTR !

    _FONT @ IF _FONT A@ ELSE _SYSFONT @ THEN 'FONT !
    128 0 DO  ( 128 Characters in set )
         8 0 DO  ( 8 Lines in each character )
              J I 256 * + 'FONT @ + C@ ( get a line of the character )
              _PNTR @ C! 2 _PNTR +! ( store a line, inc pointer )
         LOOP
    LOOP ;

: SHOW-BIT ( N -- ) IF 42 ELSE BL THEN EMIT ;

: SHOW-BYTE ( N -- )
    DUP 128 AND SHOW-BIT
    DUP 64 AND SHOW-BIT
    DUP 32 AND SHOW-BIT
    DUP 16 AND SHOW-BIT
    DUP 8 AND SHOW-BIT
    DUP 4 AND SHOW-BIT
    DUP 2 AND SHOW-BIT
        1 AND SHOW-BIT ;

: SHOW-WORD
    DUP 256 / SHOW-BYTE SHOW-BYTE ;

: CALC-AD ( N -- ) 16 * 130 + _PFONT + ;

: GET-WIDTH
    1 _WID !
    16 0 DO
         2* 65535 AND DUP IF I 2+ _WID ! THEN
    LOOP DROP _WID @ ;

: STASH-IT ( save new width of cell )
    1 _WIDTH !
    _FLAG @ IF
         _CHAR @ CALC-AD _PNTR ! ( get address of char )
         _PFONT W@ 0 DO ( for # of lines do )
              _PNTR @ I 2* + W@ GET-WIDTH _WIDTH @ MAX _WIDTH !
         LOOP
         _WIDTH @ _CHAR @ _PFONT 2+ + C!
    THEN ;

: SHOW-H
    _CHAR @ _PFONT 2+ + C@ 57 18 GOTOXY ." Char width:" . ;

: SHOW-CHAR ( N -- )
    STASH-IT
    DUP _CHAR !  1 _FLAG !  SHOW-H
    CALC-AD _PNTR ! ( get address of character )
    _PFONT W@ ( get # of lines in font )
    0 DO
         5 I 2 + GOTOXY
         _PNTR @ I 2* + W@ SHOW-WORD
    LOOP ;

: SAVE-IT
    " PFONT.PRO"NEWFILE _HANDLE ! _HANDLE @ 0> IF
    _HANDLE @ _PFONT 2178 WRITE
    _HANDLE @ CLOSE
    SP! THEN ;

: LOAD-IT
    " PFONT.PRO"OPEN _HANDLE ! _HANDLE @ 0> IF
    _HANDLE @ _PFONT 2178 READ
    _HANDLE @ CLOSE
    SP! THEN ;

CREATE _BITS
    32768 W, 16384 W, 8192 W, 4096 W, 2048 W, 1024 W, 512 W,
      256 W, 128 W, 64 W, 32 W, 16 W, 8 W, 4 W, 2 W, 1 W,

: SCROLL-IT
    _CHAR @ CALC-AD _PNTR !
    8 0 DO
         I 2* _PNTR @ + W@ 2* I 2* _PNTR @ + W!
    LOOP _CHAR @ SHOW-CHAR ;

: EDIT
    MOUSEXY 8 / SWAP 8 / SWAP ( convert to text coordinates )
    4 1 21 _PFONT W@ 2 + ?INBOX IF
         2- ( calc y ) 2* _CHAR @ CALC-AD + _PNTR !
         5 - ( calc x ) 2* _BITS + W@ _PNTR @ W@ XOR _PNTR @ W!
         _CHAR @ SHOW-CHAR
    ELSE 2DROP BEEP THEN ;

: FONT-ED
    _FLAG 0!
    MEDRES NEW-FONT
    _P-BOX DRAWTREE 37 18 GOTOXY ."  Char height:" _PFONT W@ . SPACE

    BEGIN

    BEGIN 60SYNCH MOUSEXY _MBUFF UNSPRITE _MOUSE _MBUFF SPRITE
    ?KEY BUTTONS OR OR UNTIL _MBUFF UNSPRITE

    ?KEY IF
        KEY DUP 128 < IF SHOW-CHAR ELSE DROP THEN

    ELSE

        _P-BOX GOTCLICK WAITBUTTON

        _OBJ @
             BEGCASE
             CASE 0 OF EDIT ;;
             CASE 1 OF NEW-FONT ;;
             CASE 2 OF QUIT ;;
             CASE 3 OF SAVE-IT ;;
             CASE 4 OF LOAD-IT ;;
             CASE 5 OF SCROLL-IT ;;
             ENDCASE

    THEN
    0 UNTIL  ;

: TEST1
   PAGE 0 2 GOTOXY

   100 0 DO
       0 0 GOTOXY
       91 65 DO I EMIT LOOP
       0 1 GOTOXY
       123 97 DO I EMIT LOOP
   LOOP ;

: TEST2
   _PFONT _PROP !
   PAGE 0 2 GOTOXY

   100 0 DO
       _TX 0!
       91 65 DO I PEMIT LOOP
       8 _TX !
       123 97 DO I PEMIT LOOP
   LOOP ;

QUIT

