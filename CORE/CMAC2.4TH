
( CMAC Model - based on Albus' work )

CREATE CMAC-DAT 100000 ALLOT  ( ALLOCATE 90x90x4 bytes )
CREATE CMAC-OFF 0 , 50 , 40 , 30 , 20 , 10 ,
CREATE _WIDTH 7 ,
CREATE _SCALE 1000 ,

: RAW@CMAC ( X Y --- @CMAC-DAT )
   360 * SWAP 4* CMAC-DAT + + @ ( 360*Y + 4*X + CMAC-DAT )
;

: RAW!CMAC ( DATA X Y --- )
   360 * SWAP 4 * CMAC-DAT + + !
;

: GET-CMAC-ADDR ( X Y I --- ADDRESS )
     >R
     SWAP                     ( Y X --- )
     CMAC-OFF I 4* + @        ( Y X OFFSET --- )
     + 360 _WIDTH @ 1- / /    ( Y X+OFFSET/60 --- )
     SWAP                     ( XINDEX Y --- )
     CMAC-OFF I 4* + @        ( XINDEX Y OFFSET --- )
     + 360 _WIDTH @ 1- / /    ( XINDEX Y+OFF/60 --- )
     _WIDTH @ MOD             ( XINDEX Y+OFF/60mod7 --- )
     4*                       ( XINDEX YINDEX*4bytes --- )
     SWAP                     ( YREL XINDEX --- )
     _WIDTH @ 4* *            ( YREL XREL --- )
     +                        ( RELADDRESS --- )
     CMAC-DAT +               ( ADDRESS --- )
     R> DROP
;


VARIABLE _CMAC-TOT
( -------------------------------------------------------------- )
: @CMAC ( X Y --- @CMAC )
  0 _CMAC-TOT !

  _WIDTH @ 1- 0 DO
     2DUP                   ( X Y X Y --- )
     I GET-CMAC-ADDR        ( X Y ADDRESS --- ) ( GET ELEMENT i )
     @ _CMAC-TOT +!
  LOOP

  2DROP
  _CMAC-TOT @
;


VARIABLE _DELTA
VARIABLE _DATA
( -------------------------------------------------------------- )
: !CMAC ( DATA X Y G --- )

  _DELTA !                ( STORE DELTA )
  ROT _DATA !             ( STORE THE DATA SOMEWHERE )
  2DUP @CMAC              ( X Y CMAC-DATA --- )
  _DATA @ SWAP -          ( X Y DESIRED-ACTUAL --- )
  _DELTA @ * _SCALE @ /
  _WIDTH @ 1- /           ( X Y D-A*G/6 ---     BECAUSE 6 STORAGE CELLS )
  _DATA !                 ( X Y ---    STORE THE INCREMENTAL VALUE )

( IF _DATA < ERROR DONT DO ANYTHING )

  _WIDTH @ 1- 0 DO
    2DUP                    ( X Y X Y --- )
    I GET-CMAC-ADDR         ( X Y ADDR --- )
    _DATA @ SWAP            ( X Y DATA ADDR --- )
    +!                      ( X Y --- )
  LOOP
  2DROP
;

( -------------------------------------------------------------- )
: CLEAR-CMAC ( --- )
   90 0 DO
      90 0 DO
         0 J I RAW!CMAC
      LOOP
   LOOP
;

: CALC-PXY ( X Y --- PXY )
   10000 SWAP *SIN
   SWAP 10000 SWAP *SIN  ( SINX * SINY )
   * 10000 /
;

: PLOT-CMAC ( --- )
   90 0 DO
     90 0 DO
        I                             ( CALC X COORD )
        100 J + * 100 /               ( SCALE IT  )
        3 * 2/
        J 50 +                        ( GET Y )
        I 4* J 2* @CMAC 200 / -       ( OFFSET IT VERTICALLY )
      ( I 4* J 2* CALC-PXY 200 / - )  ( FAKE THE FUNCTION )
        2DUP
        3 SETCOLOR PLOT
        2DUP
        1 SETCOLOR 1+ PLOT
        0 SETCOLOR 1+ PLOT
     LOOP
   LOOP
;

VARIABLE _ALPHA

: ENTER-POINT
   500 _ALPHA !
   500 0 DO
      RANDOM 360 MOD RANDOM 180 MOD 2DUP
      CALC-PXY ROT ROT _ALPHA @ !CMAC
      _ALPHA @ 99 * 100 / _ALPHA !
      _ALPHA @ 5 < IF
        5 _ALPHA !
      THEN
   LOOP
;

: CMAC ( --- )

   LOWRES
   CLEAR-CMAC
   ENTER-POINT
   LOWRES
   PLOT-CMAC
;

EXIT

