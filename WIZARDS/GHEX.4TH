DECIMAL

: WIZ ( FORGET WIZ TO EMPTY MEMORY ) ;

: VAR VARIABLE ;

( check _PLAYER when determining the color of a thing. )
VAR _PLAYER ( the player number we are currently concerned with. )

32 32 * 4* CONSTANT _ARRAY-SIZE
CREATE _HEX-ARRAY ( the screen map )
    _ARRAY-SIZE ALLOT

CREATE GBUF 266 ALLOT
CREATE _CBUFF 266 ALLOT

0  CONSTANT _EMPTY
1  CONSTANT _WRAITH1
2  CONSTANT _WRAITH2
3  CONSTANT _WRAITH3
4  CONSTANT _WIZARD0
5  CONSTANT _WIZARD1
6  CONSTANT _WIZARD2
7  CONSTANT _WIZARD3
8  CONSTANT _DOLMEN
9  CONSTANT _DEMON
10 CONSTANT _ELEMENTAL
11 CONSTANT _GOLEM

16 CONSTANT _STREAM
17 CONSTANT _WRAITH*1
18 CONSTANT _WRAITH*2
19 CONSTANT _WRAITH*3

1  CONSTANT _LAVA
2  CONSTANT _MARSH
3  CONSTANT _ROCK

{  ( * Universal wizards case structure * )
           BEGCASE
              CASE _EMPTY     OF ;;
              CASE _WRAITH1   OF ;;
              CASE _WRAITH2   OF ;;
              CASE _WRAITH3   OF ;;
              CASE _WIZARD0   OF ;;
              CASE _WIZARD1   OF ;;
              CASE _WIZARD2   OF ;;
              CASE _WIZARD3   OF ;;
              CASE _DOLMEN    OF ;;
              CASE _DEMON     OF ;;
              CASE _ELEMENTAL OF ;;
              CASE _GOLEM     OF ;;
              CASE _STREAM    OF ;;
              CASE _WRAITH*1  OF ;;
              CASE _WRAITH*2  OF ;;
              CASE _WRAITH*3  OF ;;
              ELSECASE           ;;
           ENDCASE
}

VARIABLE _GX              VARIABLE _GY

CREATE _CURSOR
    0 W, 0 W, 0 W, 15 W, 11 W,
    BINARY
    0000000000000000 W, 0000011111100000 W,
    0000101010100000 W, 0001000000001000 W,
    0000000000000000 W, 0010000000000100 W,
    0001010101010100 W, 0100000000000010 W,
    0000000000000000 W, 1000000000000001 W,
    1010101010101010 W, 0000000000000000 W,
    0000000000000000 W, 1000000000000001 W,
    0001010101010100 W, 0100000000000010 W,
    0000000000000000 W, 0010000000000100 W,
    0000101010100000 W, 0001000000001000 W,
    0000000000000000 W, 0000011111100000 W,
    0 , 0 , 0 , 0 , 0 ,
    DECIMAL

: ACCESS-HEX 1+ 128 * SWAP 1+ 4* + _HEX-ARRAY + ;

: CELL@ ( x y --- n )
    ACCESS-HEX @ ;

: CELL! ( n x y --- )
    ACCESS-HEX ! ;

: INIT-HEX-ARRAY _HEX-ARRAY _ARRAY-SIZE 0 FILL ;

( =------------------------------------------------------------= )

: CHOOSE-TERRAIN ( HX HY --- sprite )
    CELL@ 256 / 255 AND

           BEGCASE
              CASE _EMPTY OF _HEXSHAPE ;;
              CASE _LAVA  OF _HEXSHAPE ;;
              CASE _MARSH OF _HEXSHAPE ;;
              CASE _ROCK  OF _HEXSHAPE ;;
              ELSECASE _HEXSHAPE ;;
           ENDCASE ;

: CHOOSE-STREAM ( HX HY --- sprite )
    CELL@ 255 AND
           _STREAM >= IF _SSHAPE ELSE 0 THEN ;

: CHOOSE-SHAPE  ( HX HY --- sprite )
    CELL@ 255 AND

           BEGCASE  ( choose a sprite )
              CASE _EMPTY     OF 0         ;;
              CASE _WRAITH1   OF _WSHAPE   ;;
              CASE _WRAITH2   OF _WSHAPE   ;;
              CASE _WRAITH3   OF _WSHAPE   ;;
              CASE _WIZARD0   OF _ZSHAPE   ;;
              CASE _WIZARD1   OF _ZSHAPE   ;;
              CASE _WIZARD2   OF _ZSHAPE   ;;
              CASE _WIZARD3   OF _ZSHAPE   ;;
              CASE _DOLMEN    OF _DSHAPE   ;;
              CASE _DEMON     OF 0         ;;
              CASE _ELEMENTAL OF 0         ;;
              CASE _GOLEM     OF 0         ;;
              CASE _STREAM    OF 0         ;;
              CASE _WRAITH*1  OF _WSHAPE   ;;
              CASE _WRAITH*2  OF _WSHAPE   ;;
              CASE _WRAITH*3  OF _WSHAPE   ;;
              ELSECASE 0 ;;
           ENDCASE ;

: SCORE
    3 TEXTCOLOR C-OFF ."    " R-ON ."  WIZARD 1 " R-OFF
    ."   MAGIC= 9  DOLMENS= 3" ;

: CHECK-XY ( HX HY --- HX HY FLAG )
    2DUP + 12 < >R       ( off top? )
    2DUP + 48 > R> OR >R ( off bottom? )
    2DUP - 12 > R> OR >R ( off left? )
    2DUP - -13 < R> OR NOT ; ( off right? )

: FINDXY ( HX HY --- F )
    CHECK-XY DUP IF -ROT
       SWAP 12 - SWAP
       2DUP
       SWAP - 12 * _GX !
       + 5 * _GY !
    ELSE -ROT 2DROP THEN ;

: ?SPRITE
     ?DUP IF GBUF SPRITE
     ELSE 2DROP THEN ;

: DRAW-HEX ( HX HY --- )
    2DUP FINDXY IF
      2DUP CHOOSE-TERRAIN _GX @ _GY @ ROT GBUF SPRITE
      2DUP CHOOSE-STREAM  _GX @ _GY @ ROT ?SPRITE
           CHOOSE-SHAPE   _GX @ _GY @ ROT ?SPRITE
    ELSE 2DROP THEN ;

: SCREEN
    31 0 DO
      31 0 DO
         I J DRAW-HEX
      LOOP
    LOOP ;

( ====-------------------------------------------==== )

VARIABLE _TEMPX   VAR _TEMPY   VAR _TEMPX2   VAR _TEMPY2
VAR _HEX-X  VAR _HEX-Y
VAR _D-TOG

( _TEMPX and _TEMPY hold the mouse coords from before the mouse was moved.
    _TEMPX2 and _TEMPY2 hold the new coords. )

: MOUSE-DIR ( --- dx dy )
    _TEMPX2 @ _TEMPX @ = IF  ( is X the same?       )
         _TEMPY2 @ _TEMPY @ < IF  ( is X same, y less?   )
             -1 -1      ( yes, move cursor up  )
         ELSE 1  1 THEN ( no, move cursor down )

    ELSE _TEMPY2 @ _TEMPY @ = IF
            _TEMPX2 @ _TEMPX @ < IF
                0 -1 ELSE -1 0 THEN
            _D-TOG @ 0= DUP _D-TOG ! IF
                1+ SWAP 1+ SWAP THEN
         ELSE
            _TEMPY2 @ _TEMPY @ < IF
                0 -1 ELSE 1 0 THEN
            _TEMPX2 @ _TEMPX @ > IF
                SWAP THEN
         THEN
    THEN ;

VARIABLE _CNTR

: MULTI 0 0 GOTOXY 1 _CNTR +! _CNTR @ . ;

: PNT-HEX ( --- HX HY )
    15 15 _HEX-Y ! _HEX-X !

 BEGIN
    _HEX-X @ _HEX-Y @ FINDXY IF
         _GX @ _GY @ _CURSOR _CBUFF SPRITE THEN

    100 DUP _TEMPY ! _TEMPX !
    100 DUP MOUSEXY!

    BEGIN
         MOUSEXY 2DUP _TEMPY2 ! _TEMPX2 !
            _TEMPY @ - ABS 2 > SWAP _TEMPX @ - ABS 2 > OR
         BUTTONS OR OR
    DUP NOT IF MULTI THEN
    UNTIL

    BUTTONS OR NOT IF

       MOUSE-DIR ( returns: dx dy )

       _HEX-Y @ + SWAP _HEX-X @ + SWAP CHECK-XY IF
            _HEX-Y ! _HEX-X !
       ELSE 2DROP THEN

       _CBUFF UNSPRITE

    THEN

 BUTTONS OR UNTIL _HEX-X @ _HEX-Y @ _CBUFF UNSPRITE ;

: TEST
      TOSMOUSE
      LOWRES 0 24 GOTOXY
      INIT-HEX-ARRAY
      SCREEN SCORE PNT-HEX
      0 0 GOTOXY SWAP . SPACE . 2 SPACES ;

QUIT



