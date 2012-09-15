
( *==============================================* )
( *=======------------       -------------=======* )
( *=====      Fusion Font Editor v1.0       =====* )
( *=====  --- software by Nick Porcino ---  =====* )
( *=====------------------------------------=====* )
( *=== copyright (c>1986  all rights reserved ===* )
( *=====      by Fusion Technologies        =====* )
( *=======------------       -------------=======* )
( *==============================================* )

.( ** FUSION FONT EDITOR )

DECIMAL
VARIABLE _EDFONT   VARIABLE _TOGGLE
VARIABLE _EDCHAR
VARIABLE _FX       VARIABLE _FY

CREATE F-ARRAY 2048 YADJ ALLOT
CREATE _SHADOW 14 5 * ALLOT

CREATE DUMMY
    3 , 2 , 20 , 3 , 0 , ,"  Options: "

CREATE U-BUTTON
    2 , 1 ,
    45 , 20 ,
    ,"  UNDO CHAR "

CREATE T-BUTTON
    2 , 1 ,
    2 , 22 ,
    ,"  TOGGLE FONT "

CREATE S-BUTTON
    2 , 1 ,
    18 , 22 ,
    ,"  STORE FONT "

CREATE D-BUTTON
    2 , 1 ,
    33 , 22 ,
    ,"  DISK ACCESS "

CREATE X-BUTTON
    2 , 1 ,
    48 , 22 ,
    ,"  ABORT "

CREATE W-BUTTON
    2 , 1 ,
    26 , 22 , ,"  SAVE FONT TO DISK "

CREATE R-BUTTON
    2 , 1 ,
    3 , 22 , ,"  READ FONT FROM DISK "

CREATE _FILE$
    6 ,
    31 , 20 , 1 , 3 ,
    ," TESTFONT.FED " 0 ,

CREATE _DISK$
    3 , 14 , 20 , 3 , 1 ,
    ,"  Disk filename: "

CREATE _FILE-BOX  ( TOGGLE BOX )
    1 , 2 , 1 , _SOLID A, 1 ,
    0 , 19 , 58 , 24 ,
    5 , _DISK$ A,
        _FILE$ A, X-BUTTON A, W-BUTTON A, R-BUTTON A,

CREATE M-FED-BOX3  ( TOGGLE BOX )
    1 , 2 , 1 , _SOLID A, 1 ,
    0 , 19 , 58 , 24 ,
    6 , DUMMY A, T-BUTTON A, S-BUTTON A,
     X-BUTTON A, D-BUTTON A, U-BUTTON A,

CREATE M-FED-BOX2  ( SELECTED BOX )
    1 , 2 , 1 , _SOLID A, 1 ,
    60 , 0 , 76 , 6 ,
    0 ,

CREATE M-FED-BOX1  ( MAIN EDIT BOX )
    1 , 2 , 1 , _SOLID A, 1 ,
    0 , 0 , 58 , 18 ,
    2 , M-FED-BOX2 A, M-FED-BOX3 A,

( *==========================================================* )

: MOUSETXY MOUSEXY 8 YADJ / SWAP 8 / SWAP ;
: MOUSEXY MOUSEXY 4 YADJ / SWAP 4/ SWAP ;

( *----------------------------------------------------------* )

: INIT-FED
     _EDFONT @ F-ARRAY 2048 YADJ CMOVE
     _SHADOW 14 4 * 0 FILL
     _EDCHAR 0! ;

: SET-FONT
    _TOGGLE @ IF F-ARRAY ELSE _SYSFONT @ THEN LOAD-FONT ;

: SHOW-DOT ( flag bit# --- )
    SWAP >R
    _SOLID 1 ROT
    4* _FX @ +   _FY @
    OVER 3 + OVER 4 YADJ 1- +
    R> IF 3 ELSE 0 THEN SETCOLOR
    FILLRECT ;

: SHOW-LINE ( bitmap --- )
    DUP 128 AND 0 SHOW-DOT
    DUP 64  AND 1 SHOW-DOT
    DUP 32  AND 2 SHOW-DOT
    DUP 16  AND 3 SHOW-DOT
    DUP  8  AND 4 SHOW-DOT
    DUP  4  AND 5 SHOW-DOT
    DUP  2  AND 6 SHOW-DOT
         1  AND 7 SHOW-DOT ;

: SHOW-CELL
      8 0 DO
         DUP C@ ( get a line of the character )
         SHOW-LINE
         4 YADJ _FY +!
         256 YADJ +
      LOOP DROP ;

: SKETCH ( x y char )
      F-ARRAY +
      -ROT 1- 32 * 8 YADJ +
      SWAP 61 - 32 YADJ * 8 + ( get initial x and y )
      _FX ! _FY !
      SHOW-CELL ;

: DRAW-FONT
     3 TEXTCOLOR 0 BACKCOLOR
     16 0 DO ( Y ) ( DRAW SYFONT MATRIX )
       16 0 DO ( X )
         I 60 + J 7 + GOTOXY
         SCREEN: >OUT
           I J 16 * + EMIT
         CON: >OUT
       LOOP
     LOOP
     _SYSFONT @ LOAD-FONT ;

: DRAW-SHADOW
     3 TEXTCOLOR 0 BACKCOLOR
     4 0 DO ( Y ) ( DRAW SHADOW MATRIX )
       14 0 DO ( X )
         I 61 + J 1+ GOTOXY
         SCREEN: >OUT
         SET-FONT I J 14 * + _SHADOW + C@
         DUP 0 = IF DROP 32 THEN
         EMIT
         CON: >OUT
       LOOP
     LOOP
     _SYSFONT @ LOAD-FONT ;

: DRAW-SCREEN
     _SYSFONT @ LOAD-FONT
     M-FED-BOX1 DRAWTREE
         _TOGGLE 0!
         DRAW-FONT  DRAW-SHADOW

     1 SETCOLOR
     168 8 DO ( DRAW GRID )
        8 I YADJ  456 I YADJ  LINE
     32 +LOOP

     457 8 DO
        I 8 YADJ  I 136 YADJ  LINE
     32 +LOOP ;

: ERASE-CHAR
    3 TEXTCOLOR 2 BACKCOLOR
    20 20 GOTOXY 23 SPACES  _EDCHAR 0! ;

: SHOW-CHAR ( char --- )
         SCREEN: >OUT
           DUP EMIT SPACE
           F-ARRAY LOAD-FONT EMIT
           _SYSFONT @ LOAD-FONT
         CON: >OUT ;

: CHECK-FONTS
    3 TEXTCOLOR 2 BACKCOLOR
    MOUSETXY
    59 6 76 23 ?INBOX IF
       7 - 16 * SWAP 60 - + DUP _EDCHAR !
       20 20 GOTOXY
       ." EDITING CHAR: " SHOW-CHAR
    ELSE 2DROP ERASE-CHAR THEN ;

( *-------------------------------------------------------------* )

VARIABLE _LOCALX  VARIABLE _LOCALY  VARIABLE _LOCALC

: FIX-DISPLAY 3 TEXTCOLOR 0 BACKCOLOR

      _LOCALC @ DUP DUP 16 MOD 60 + SWAP 16 / 7 + GOTOXY
      SCREEN: >OUT
         SET-FONT EMIT
      CON: >OUT

      56 0 DO
           _SHADOW I + C@ _LOCALC @ = IF
                I 14 MOD 61 + I 14 / 1+ 2DUP GOTOXY
                _LOCALC @ SKETCH
                SCREEN: >OUT
                SET-FONT _LOCALC @ EMIT
                CON: >OUT
           THEN
       LOOP
       _SYSFONT @ LOAD-FONT ;

CREATE _BITS 128 C, 64 C, 32 C, 16 C, 8 C, 4 C, 2 C, 1 C,

: EDIT-FONT
    MOUSEXY 2 YADJ - SWAP 2- SWAP 2DUP _LOCALY ! _LOCALX !
    -1 -1 YADJ 112 32 YADJ ?INBOX IF
         2DUP 8 YADJ / 14 * SWAP 8 / + _SHADOW + C@ ?DUP IF
              DUP _LOCALC ! -ROT
              8 MOD 256 * SWAP  ( get y )
              8 MOD SWAP        ( get x )
              ROT + F-ARRAY + DUP >R
              C@  ( get cell we're working on )
              SWAP
              _BITS + C@ XOR
              R> C!

              FIX-DISPLAY

         ELSE 2DROP THEN
    ELSE 2DROP THEN BEGIN BUTTONS OR 0= UNTIL ;

: CHECK-SHADOW
    MOUSETXY
    60 0 76 5 ?INBOX IF
       _EDCHAR @ IF 2DUP
          _EDCHAR @ SKETCH
          1- 14 * SWAP 61 - + _SHADOW + _EDCHAR @ SWAP C!
          DRAW-SHADOW
          ERASE-CHAR
       ELSE 2DROP THEN
    ELSE 2DROP THEN ;

: TOGGLE-FONT
    _TOGGLE @ 0= _TOGGLE !
    SET-FONT
    DRAW-FONT DRAW-SHADOW ;

: STORE-FONT
     F-ARRAY _EDFONT @ 2048 YADJ CMOVE ;

( *-----------------------------------------------------* )

: WRITE-FONT
     _FILE$ 20 + COUNT NEWFILE DUP 0> IF
         _HANDLE !
         F-ARRAY HERE 602 + 2048 CMOVE
         _HANDLE @ HERE 2650 WRITE DROP
         _HANDLE @ CLOSE DROP
     ELSE DROP 20 20 GOTOXY ." Write error" KEY DROP THEN ;

: READ-FONT
    _FILE$ 20 + COUNT OPEN DUP 0> IF
       _HANDLE !
       _HANDLE @ F-ARRAY 602 READ DROP
       _HANDLE @ F-ARRAY 2650 READ DROP
       _HANDLE @ CLOSE DROP
   ELSE DROP 20 20 GOTOXY ." Read error " KEY DROP THEN ;

: SAVE-FONT
     _SYSFONT @ LOAD-FONT
     " FUSION.FED" OPEN DUP 0> IF
        DUP _HANDLE !
        HERE 602 READ ( read in GEM font header information )
        0> IF
           _HANDLE @ CLOSE
           _FILE-BOX DRAWTREE

           BEGIN
                MOUSEXY 4 YADJ * 2+ SWAP 4* 2+ SWAP
                   60SYNCH _MBUFF UNSPRITE
                   _MOUSE _MBUFF SPRITE

                BUTTONS IF
                    _MBUFF UNSPRITE
                    _FILE-BOX GOTCLICK
                    _OBJ @
                       BEGCASE
                          CASE 0 OF 0 ;;
                          CASE 1 OF 1 ;;
                          CASE 2 OF 1 ;;
                          CASE 3 OF WRITE-FONT 1 ;;
                          CASE 4 OF READ-FONT 1 ;;
                       ENDCASE
                ELSE 0 THEN

            OR UNTIL
           M-FED-BOX3 DRAWTREE

        ELSE DROP 20 20 GOTOXY ." FUSION.FED read error"
           _HANDLE @ CLOSE THEN
     ELSE 20 20 GOTOXY ." FUSION.FED not present" THEN ;

: ABORT-EDIT
    _MBUFF UNSPRITE
    3 TEXTCOLOR 0 BACKCOLOR
    C-ON CR ABORT ;

: UNDO-CHAR
     _EDCHAR @ IF
         2048 0 DO
              I _EDFONT @ + _EDCHAR @ + C@  ( source )
              I F-ARRAY   + _EDCHAR @ + C!  ( dest )
         256 +LOOP
         FIX-DISPLAY
         ERASE-CHAR
     ELSE 20 20 GOTOXY ." No char to undo." THEN ;

: CHECK-TOGS
    _OBJ @
         BEGCASE
            CASE 0 OF ;;
            CASE 1 OF TOGGLE-FONT ;;
            CASE 2 OF STORE-FONT ;;
            CASE 3 OF ABORT-EDIT ;;
            CASE 4 OF SAVE-FONT ;;
            CASE 5 OF UNDO-CHAR ;;
         ENDCASE ;

: FONT-ED ( ADDR --- )
    _EDFONT !
    MEDRES
    _SYSFONT @ LOAD-FONT
    INIT-FED DRAW-SCREEN
    TOSMOUSE

    BEGIN
         MOUSEXY 4 YADJ * 2+ SWAP 4* 2+ SWAP
            60SYNCH _MBUFF UNSPRITE
            _MOUSE _MBUFF SPRITE

         BUTTONS OR IF
            _MBUFF UNSPRITE
            M-FED-BOX1 GOTCLICK
            _BOX @
              BEGCASE
                 CASE 0 OF CHECK-FONTS ;;
                 CASE 1 OF EDIT-FONT ;;
                 CASE 2 OF CHECK-SHADOW ;;
                 CASE 3 OF CHECK-TOGS ;;
              ENDCASE
            THEN

         ?KEY IF KEY DROP ABORT-EDIT THEN

         0 UNTIL ;

EXIT

