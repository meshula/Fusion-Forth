DECIMAL
 ( ********************************************************* )
 ( * FUSION Forth graphics extensions                      * )
 ( *                                                       * )
 ( * including: TURTLE GRAPHICS                            * )
 ( *            XBIOS EXTENSIONS                           * )
 ( *                                                       * )
 ( * FILE: GRAFIX.4TH                                      * )
 ( ********************************************************* )
 ( * written by Nick Porcino and Don Palmer                * )
 ( *   copyright (C>1986 FusionCorp                        * )
 ( ********************************************************* )

: ANGSET DUP 0> IF 360 MOD  ( returns an angle from 0-360 )
    ELSE NEGATE 360 MOD NEGATE 360 + THEN ;

: */ >R * R> /  ;

: *SIN GETSIN * 32768/ ;
: *COS GETCOS * 32768/ ;
: *TAN DUP GETSIN SWAP GETCOS */ ;

VARIABLE _TURTX  VARIABLE _TURTY  VARIABLE _TURTANG
VARIABLE _PENSTATE

: PENDOWN 1 _PENSTATE ! ;   : PENUP _PENSTATE 0! ;

: MOVETO ( x y --- ) 100 * _TURTY ! 100 * _TURTX ! ;
: GETXY  ( --- x y ) _TURTX @ 100 / _TURTY @ 100 / ;
: DRAWTO ( x y --- ) OVER OVER GETXY LINE MOVETO ;
: TURNTO ( n ---   ) _TURTANG ! ;

: HOME GETREZ DUP IF 32000 _TURTX ! ELSE 16000 _TURTX ! THEN
     2 = IF 20000 _TURTY ! ELSE 10000 _TURTY ! THEN
     PENDOWN  0 _TURTANG ! ;

: LEFT _TURTANG @ SWAP - ANGSET _TURTANG ! ; ( n -- )
: RIGHT _TURTANG @ + ANGSET _TURTANG ! ;     ( n -- )
: FORWARD 100 * >R _TURTX @ 100 / _TURTY @ 100 / R> DUP
        _TURTANG @ *SIN _TURTX @ + DUP _TURTX ! 100 / SWAP
        _TURTANG @ *COS _TURTY @ + DUP _TURTY ! 100 /
        _PENSTATE @ IF
          LINE
        ELSE DROP DROP DROP DROP THEN ;

: BOX 4 0 DO DUP FORWARD 90 RIGHT LOOP DROP ;

: YADJ ( n -- n ) ( doubles Y if monochrome. )
     GETREZ 2 = IF 2* THEN ;

 ( * FONT EXTENSIONS:                                      * )

VARIABLE _SYSFONT

: INIT-FONT GETREZ 2 = IF 16595294 ELSE 16592642 THEN _SYSFONT ! ;

( -------------- )
    INIT-FONT
( -------------- )

: LOAD-FONT ( addr --- ) DUP AINIT 22 - !  _FONT A! ;

: <ENTER-FONT> ( addr n --- addr true )
               ( addr n --- false )
    OPEN ?DERROR DUP _HANDLE !  0> IF
         _HANDLE @ HERE  602 READ DROP
         _HANDLE @ HERE 2048 YADJ READ ?DERROR 0> IF
              HERE DUP LOAD-FONT
              2048 YADJ ALLOT
         ELSE ."  Error while loading font." THEN
    ELSE ."  Unable to open font file." THEN ;

: ENTER-FONT GET-WORD IF <ENTER-FONT> THEN ;

( format:   CREATE <font name> ENTER-FONT <file name>
            <font name> LOAD-FONT
      or:   _FONT @ LOAD-FONT      )

 ( ********************************************************* )
 ( * XBIOS extensions                                      * )
 ( ********************************************************* )

: 60SYNCH 37 L>W 1 XBIOS DROP ;
: SETPAL ( pal $rgb ) SWAP >R L>W R> L>W 7 L>W 3 XBIOS DROP ;
: SCREENBASE 2 L>W 1 XBIOS ;
: RANDOM 17 L>W 1 XBIOS ; ( returns a 24 bit random number )

: SETPHYS ( addr --- ) ( set physical screen base )
     >R -1 L>W R> -1 5 L>W 6 XBIOS DROP ;

: SETCOLORS  ( addr --- )  ( given a palette address, )
    16 0 DO                ( load in that palette     )
      DUP I 2* + W@ I SWAP SETPAL ( set color I       )
    LOOP DROP ;

HEX
CREATE LOWCOLORS
 000 W, 500 W, 730 W, 750 W, 770 W, 470 W, 075 W, 067 W,
 046 W, 037 W, 005 W, 222 W, 333 W, 444 W, 555 W, 777 W,

CREATE MEDCOLORS
 125 W, 000 W, 037 W, 567 W, 770 W, 470 W, 070 W, 075 W,
 067 W, 046 W, 037 W, 005 W, 507 W, 707 W, 704 W, 777 W,
DECIMAL

: HICLIP  0 0 639 399 SETCLIP   0 0 639 399 MOUSECLIP ;
: MEDCLIP 0 0 639 199 SETCLIP   0 0 639 199 MOUSECLIP ;
: LOWCLIP 0 0 319 199 SETCLIP   0 0 319 199 MOUSECLIP ;

: <RES>
     _FONT @ IF
     _FONT A@ LOAD-FONT  27 EMIT ." v" THEN ;

: HIRES GETREZ 2 =
    IF PAGE HICLIP
    THEN
    <RES> ;

: LOWRES GETREZ 2 <>
    IF LOWRES LOWCOLORS SETCOLORS LOWCLIP
    ELSE HIRES THEN
    <RES> ;

: MEDRES GETREZ 2 <>
    IF MEDRES MEDCOLORS SETCOLORS MEDCLIP
    ELSE HIRES THEN
    <RES> ;

VARIABLE _OLDBASE   VARIABLE _ALTPAGE

: INIT-FLIP
     SCREENBASE _OLDBASE !
     32000 _ALTPAGE ! ;

: END-FLIP
     _OLDBASE @ DUP
     SETLOG SETPHYS ;

QUIT






