
.( WIZARDS game setup )
( FILE: WIZSETUP.4TH )

DECIMAL

VAR _#PLAYERS

CREATE _Z-X-ARRAY ( Coordinate array holding wizard coordinates. )
    40 ALLOT

CREATE _Z-Y-ARRAY
    40 ALLOT

: TITLE-PAGE
    LOWRES C-ON
    1 TEXTCOLOR
    16 1 GOTOXY ." WIZARDS"
    1 SETCOLOR
    128 17 184 17 LINE
    2 TEXTCOLOR
    5 3 GOTOXY ." by Nick Porcino and Don Palmer"
    3 TEXTCOLOR
    0 5 GOTOXY ." copyright (C)1986 by Fusion Technologies"
    4 TEXTCOLOR
    10 6 GOTOXY ." All rights reserved."
    5 TEXTCOLOR
    8 8 GOTOXY ." Written in Fusion FORTH"
    6 TEXTCOLOR
    3 9 GOTOXY ." The complete ST development system"
    7 TEXTCOLOR
    0 12 GOTOXY ." FUSION -Technology that works like magic" ;

: #PLAYERS?

    10 TEXTCOLOR 5 BACKCOLOR
    0 17 GOTOXY ESC ." K"
    0 19 GOTOXY ESC ." K"
    0 18 GOTOXY ."  How many players? " ESC ." K"

    BEGIN
      KEY 48 - DUP
      1 >= OVER 9 <= AND IF 1 ELSE DROP 0 THEN
    UNTIL

    _#PLAYERS ! ;

: PLACE-THING ( X Y THING --- )
         >R 2DUP R> -ROT CELL! DRAW-HEX ;

: DOWN ( X Y --- X+1 Y+1 )
    1+ SWAP 1+ SWAP ;
: UP   ( X Y --- X-1 Y-1 )
    1- SWAP 1- SWAP ;
: UP-N ( X Y N --- X-N Y-N )
    SWAP OVER - ( X N Y-N )
    -ROT - SWAP ;
: D-L  ( X Y --- X-1 Y   )
    SWAP 1+ SWAP ;
: D-R  ( X Y --- X Y+1   )
    1+ ;
: U-L  ( X Y --- X Y-1   )
    1- ;
: U-R  ( X Y --- X-1 Y   )
    SWAP 1- SWAP ;

VAR _PROX-FLAG
VAR _X1 VAR _X2 VAR _Y1 VAR _Y2

: DIST ( X1 Y1 X2 Y2 --- N ) ( THE NUMBER OF HEXES BETWEEN 2 POINTS )

    _Y2 ! _X2 ! _Y1 ! _X1 !

    _Y2 @ _X1 @ + _Y1 @ - _Y2 ! ( NORMALIZE COORDINATES )
    _X1 @ _Y1 !

    _X2 @ _Y2 @ - ABS
    _Y2 @ _Y1 @ - ABS + ;

VAR _TEMP

: TEST-IT ( X Y --- X Y ) 2DUP
      _TEMP 0!
      60SYNCH
      2DUP FINDXY IF _GX @ _GY @ _CURSOR GBUF SPRITE 1 _TEMP ! THEN
      CELL@ _PROX-FLAG +! 60SYNCH _TEMP @ IF GBUF UNSPRITE THEN
      _PROX-FLAG @ IF BEEP THEN ;

: GOOD-SPOT? ( X Y --- X Y TRUE )
             ( X Y --- FALSE )
    2DUP
    + 18 < >R 2DUP
    + 43 > R> OR >R 2DUP
    - 9 > R> OR >R 2DUP
    - -10 < R> OR NOT
    IF

       0 _PROX-FLAG ! ( set to OK )

       2DUP
       3 UP-N TEST-IT  D-R TEST-IT   D-R  TEST-IT (  3 )
       DOWN TEST-IT    D-R TEST-IT   DOWN TEST-IT (  6 )
       DOWN TEST-IT    D-L TEST-IT   D-L  TEST-IT (  9 )
       U-L  TEST-IT    D-L TEST-IT   U-L  TEST-IT ( 12 )
       U-L  TEST-IT    UP  TEST-IT   UP   TEST-IT ( 15 )
       U-R  TEST-IT    UP  TEST-IT   U-R  TEST-IT ( 18 )
       2DROP

       _PROX-FLAG @ NOT IF 1 ELSE 2DROP 0 THEN

   ELSE BEEP 2DROP 0
   THEN ;

: GET-WIZARDS
    _#PLAYERS @ 1+ 1 DO
      0 25 GOTOXY
      I TEXTCOLOR 0 BACKCOLOR
      ." PLAYER " I . ." : Place your wizard."

      I _PLAYER !

      BEGIN
         ?STACK
         ?KEY IF QUIT THEN
         PNT-HEX
         BEGIN BUTTONS OR 0= UNTIL
         GOOD-SPOT?
      UNTIL

         2DUP I 4* _Z-X-ARRAY + !  ( store wizards coordinate in array )
              I 4* _Z-Y-ARRAY + !
         2DUP _WIZARD3  PLACE-THING ( 1 wizard )
         UP              ( 2 upper dolmen )
         2DUP _DOLMEN   PLACE-THING
         UP              ( 3 highest wraith )
         2DUP _WRAITH*1 PLACE-THING
         1+              ( 4 the wraith to the right )
         2DUP _WRAITH*1 PLACE-THING
         DOWN            ( 5 the double wraith below )
         2DUP _WRAITH*2 PLACE-THING
         DOWN            ( 6 the lower right dolmen )
         2DUP _DOLMEN   PLACE-THING
         SWAP 1- SWAP    ( 7 wraith )
         2DUP _WRAITH*1 PLACE-THING
         DOWN            ( 8 wraith )
         2DUP _WRAITH*1 PLACE-THING
         SWAP 1+ SWAP    ( 9 wraith )
         2DUP _WRAITH*1 PLACE-THING
         1-              ( 10 lowest double wraith )
         2DUP _WRAITH*2 PLACE-THING
         SWAP 1+ SWAP    ( 11 wraith )
         2DUP _WRAITH*1 PLACE-THING
         UP              ( 12 lower left dolmen )
         2DUP _DOLMEN   PLACE-THING
         SWAP 1+ SWAP    ( 13 wraith )
         2DUP _WRAITH*1 PLACE-THING
         UP              ( 14 wraith )
         2DUP _WRAITH*1 PLACE-THING
         SWAP 1- SWAP    ( 15 double wraith )
         2DUP _WRAITH*2 PLACE-THING
         UP              ( 16 wraith )
              _WRAITH*1 PLACE-THING

    LOOP ;

: INIT-VARS
    _Z-X-ARRAY 40 0 FILL
    _Z-Y-ARRAY 40 0 FILL ;

: SPINNY
     HOME PENUP -30 FORWARD PENDOWN
      1 SETCOLOR 180 0 DO 15 FORWARD I 10 * 1+ RIGHT LOOP
     10000 0 DO LOOP ;

: LITTLE-SPIN MOVETO 1 SETCOLOR
    180 0 DO 2 FORWARD I 10 * 1+ RIGHT LOOP ;

: WIZARDS
      TITLE-PAGE 207 11 LITTLE-SPIN 107 11 LITTLE-SPIN
      #PLAYERS?
      INIT-HEX-ARRAY
      INIT-VARS
      0 BACKCOLOR
      PAGE C-OFF SPINNY SCREEN
      GET-WIZARDS
      KEY DROP ;

QUIT

