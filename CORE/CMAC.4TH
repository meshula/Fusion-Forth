
( CMAC Model - based on Albus' work )

CREATE CMAC-DAT 90 90 4 * * ALLOT  ( ALLOCATE 90x90x4 bytes )
CREATE CMAC-OFF 0 , 50 , 40 , 30 , 20 , 10 ,
CREATE _WIDTH 7 ,

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

  6 0 DO
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
: !CMAC ( DATA X Y G --- ) ( NOTE: A* = 49 )

  _DELTA !           ( STORE DELTA )
  ROT _DATA !        ( STORE THE DATA SOMEWHERE )
  2DUP @CMAC         ( X Y CMAC-DATA --- )
  _DATA @ SWAP -     ( X Y DESIRED-ACTUAL --- )
  _DELTA @ * 6000 /     ( X Y D-A*G/6 ---     BECAUSE 6 STORAGE CELLS )
  _DATA !            ( X Y ---    STORE THE INCREMENTAL VALUE )

( IF _DATA < ERROR DONT DO ANYTHING )

  6 0 DO
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
        J 50 +                        ( GET Y )
        I 4* J 2* @CMAC 200 / -       ( OFFSET IT VERTICALLY )
     (   I 4* J 2* CALC-PXY 200 / - ) ( FAKE THE FUNCTION )
        2DUP
        3 SETCOLOR PLOT
        2DUP
        4 SETCOLOR 1+ PLOT
        0 SETCOLOR 1+ PLOT
     LOOP
   LOOP
;

: ENTER-POINT
   500 0 DO
      RANDOM 360 MOD RANDOM 180 MOD 2DUP
      CALC-PXY ROT ROT 5 !CMAC
   LOOP
;

: CMAC ( --- )

   LOWRES
   CLEAR-CMAC
(   PLOT-CMAC )
   KEY DROP
   ENTER-POINT
   LOWRES
   PLOT-CMAC
;

EXIT

