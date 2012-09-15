
DECIMAL
: EMPTY ;

( *------------------------------------------------------* )
( *    WIZARDS                                           * )
( *               concept and programming:               * )
( *                  Don Palmer and Nick Porcino         * )
( *------------------------------------------------------* )
( *  copyright (C>1986 All rights reserved               * )
( *    FusionCorp.                                       * )
( *------------------------------------------------------* )


( Organization of the _BOARD data structure:

                     2,0                W
                  1,0   3,0          W     W
                     2,1  4,1     W     D     W
                  1,1   3,1         *2W   *2W
                0,2  2,2  4,2     W     Z     W
                  1,2   3,2          D     D
                0,3  2,3  4,3     W    *2W    W
                  1,3   3,3          W     W

  ttsmmmpp
        tt - terrain
         s - stream
       mmm - monster
        pp - player

  11111111 - Spot unoccupied.
  xxxxxxnn - Spot occupied by player nn
  xx0xxxxx - No stream in spot
  xx1xxxxx - Stream in spot
  xx0000xx - Dolmen
  nnx001xx - Wraith - strength nn
  xxx010xx - No creature
  xxx011xx - Invisible Sentry
  xx0100xx - Demon
  xx0101xx - Elemental
  xx0110xx - Golem
  nn0111xx - Wizard - number of wraiths nn
  00xxxxxx -
  01xxxxxx - Lava
  10xxxxxx - Marsh
  11xxxxxx - Ground

  11100100 - STREAM, 3 WRAITHS, player 1 )

BINARY
11011000 CONSTANT _TEST
00100000 CONSTANT _STRMBIT
00101000 CONSTANT _STREAM
00010000 CONSTANT _DEMON
00010100 CONSTANT _ELEMENTAL
00011000 CONSTANT _GOLEM
00011100 CONSTANT _WIZ0  ( naked wizard         )
11011100 CONSTANT _WIZ   ( full strength wizard )
00000000 CONSTANT _DLM   ( dolmen               )
10100100 CONSTANT _2WR   ( 2 wraiths, stream    )
01000100 CONSTANT _1WR   ( 1 wraith             )
DECIMAL

12 CONSTANT _HEIGHT
22 CONSTANT _WIDTH
3 CONSTANT _CELLW

_HEIGHT _WIDTH * CONSTANT _SPOTS

CREATE _BOARD  _SPOTS ALLOT

VARIABLE _PLAYER       VARIABLE _CELL
VARIABLE _ATTACK       VARIABLE _DEFEND
VARIABLE _COST         VARIABLE _CREATURE
VARIABLE _MAGIC1       VARIABLE _MAGIC2
VARIABLE _DOLMEN1      VARIABLE _DOLMEN2
VARIABLE _AGGRESSX     VARIABLE _AGGRESSY
VARIABLE _VICTIMX      VARIABLE _VICTIMY

( *------------------------------------------------------* )
( * The mouse:                                           * )

CREATE _MOUSE 2 W, 2 W, 0 W, 3 W, 0 W,
BINARY
      0000000000000000 W, 0 W,
      0110000000000000 W, 0 W,
      0111000000000000 W, 0010000000000000 W,
      0111100000000000 W, 0011000000000000 W,
      0111110000000000 W, 0011100000000000 W,
      0111111000000000 W, 0011110000000000 W,
      0111111100000000 W, 0011111000000000 W,
      0111111110000000 W, 0011111100000000 W,
      0101111101000000 W, 0000111000000000 W,
      0001111100000000 W, 0000111000000000 W,
      0000111110000000 W, 0000011100000000 W,
      0000111110000000 W, 0000011100000000 W,
      0000011111000000 W, 0000001110000000 W,
      0000011111000000 W, 0000001110000000 W,
      0000001111100000 W, 0000000111000000 W,
      0000001111100000 W, 0000000000000000 W,
DECIMAL

CREATE _MBUFF 266 ALLOT

: SPLAT-MOUSE MOUSEXY 60SYNCH _MBUFF UNSPRITE
      _MOUSE _MBUFF SPRITE ;

: DO-MOUSE C-OFF

  BEGIN  SPLAT-MOUSE  BUTTONS OR UNTIL
  BEGIN  SPLAT-MOUSE  BUTTONS OR 0= UNTIL

  _MBUFF UNSPRITE
  MOUSEXY C-ON ;

( *------------------------------------------------------* )
( * General subroutines                                  * )

: CELL@ ( x y --- n )
  ( returns the value of cell x,y )
     _WIDTH * + _BOARD + C@ ;

: CELL! ( n x y --- )
  ( stores n in cell x,y )
     _WIDTH * + _BOARD + C! ;

: SET-CELL ( x y n1 n2 --- )
     OR -ROT CELL! ;

: TESTUP ( x y --- f ) 2DUP OVER ODD ;

: UP  ( x1 y1 --- x1 y1 x2 y2 ) 2DUP 1- ;
: UPL ( x1 y1 --- x1 y1 x2 y2 ) TESTUP NOT IF 1- THEN
                                SWAP 1- SWAP ;
: UPR ( x1 y1 --- x1 y1 x2 y2 ) TESTUP NOT IF 1- THEN
                                SWAP 1+ SWAP ;
: LOL ( x1 y1 --- x1 y1 x2 y2 ) TESTUP IF 1+ THEN
                                SWAP 1- SWAP ;
: LOR ( x1 y1 --- x1 y1 x2 y2 ) TESTUP IF 1+ THEN
                                SWAP 1+ SWAP ;
: LO  ( x1 y1 --- x1 y1 x2 y2 ) 2DUP 1+ ;

: UCELL@  ( x y --- x y n ) UP  CELL@ ;
: ULCELL@ ( x y --- x y n ) UPL CELL@ ;
: URCELL@ ( x y --- x y n ) UPR CELL@ ;
: LLCELL@ ( x y --- x y n ) LOL CELL@ ;
: LRCELL@ ( x y --- x y n ) LOR CELL@ ;
: LCELL@  ( x y --- x y n ) CELL@ ;

: UCELL!  ( n x y --- x y ) ROT >R UP  R> -ROT CELL! ;
: ULCELL! ( n x y --- x y ) ROT >R UPL R> -ROT CELL! ;
: URCELL! ( n x y --- x y ) ROT >R UPR R> -ROT CELL! ;
: LLCELL! ( n x y --- x y ) ROT >R LOL R> -ROT CELL! ;
: LRCELL! ( n x y --- x y ) ROT >R LOR R> -ROT CELL! ;
: LCELL!  ( n x y --- x y ) ROT >R LO  R> -ROT CELL! ;

( *-------------------------------------------------------* )

: PLACE-WIZ ( x y player --- )
     1- >R SWAP EVEN SWAP
     ( place wizard )
     2DUP R@ _WIZ SET-CELL

     ( place dolmens )
     2DUP 1- R@ _DLM SET-CELL
     2DUP SWAP 1- SWAP R@ _DLM SET-CELL
     2DUP SWAP 1+ SWAP R@ _DLM SET-CELL

     ( place 3 Double wraiths, stream )
     2DUP 1+ R@ _2WR OR -ROT CELL!
     2DUP 1- SWAP 1- SWAP R@ _2WR SET-CELL
     2DUP 1- SWAP 1+ SWAP R@ _2WR SET-CELL

     ( place 9 more wraiths    )
     2DUP 2- R@ _1WR SET-CELL
     2DUP SWAP 2- SWAP R@ _1WR SET-CELL
     2DUP SWAP 2+ SWAP R@ _1WR SET-CELL
     2DUP 2- SWAP 1+ SWAP R@ _1WR SET-CELL
     2DUP 2- SWAP 1- SWAP R@ _1WR SET-CELL
     2DUP 1+ SWAP 2- SWAP R@ _1WR SET-CELL
     2DUP 1+ SWAP 1- SWAP R@ _1WR SET-CELL
     2DUP 1+ SWAP 1+ SWAP R@ _1WR SET-CELL
     2DUP 1+ SWAP 2+ SWAP R@ _1WR SET-CELL

  DROP DROP R> DROP ;

( *------------------------------------------------* )

: INIT  TOSMOUSE
     _BOARD _SPOTS -1 FILL
     4 4 1 PLACE-WIZ
     12 5 2 PLACE-WIZ
     _TEST 6 7 CELL!
     _TEST 4 9 CELL!

     _MAGIC1 0!   _MAGIC2 0!
     3 _DOLMEN1 !  3 _DOLMEN2 !

     3 BACKCOLOR 0 TEXTCOLOR
;

( *--------------------------------------------------* )
( *  Draw subroutines                                * )

: DRAW-STATUS 1 TEXTCOLOR
     70 1 GOTOXY ." Wizard 1"
     70 3 GOTOXY ." Magic:"
     70 4 GOTOXY _MAGIC1 @ . 27 EMIT ." K"
     70 5 GOTOXY ." Dolmens:"
     70 6 GOTOXY _DOLMEN1 @ . 27 EMIT ." K"

     70 9 GOTOXY ." Wizard 2"
     70 11 GOTOXY ." Magic:"
     70 12 GOTOXY _MAGIC2 @ . 27 EMIT ." K"
     70 13 GOTOXY ." Dolmens:"
     70 14 GOTOXY _DOLMEN2 @ . 27 EMIT ." K"

     70 16 GOTOXY _PLAYER @ 2 BACKCOLOR
     1 = IF ."  Wizard 1 " ELSE ."  Wizard 2 " THEN
     3 BACKCOLOR ;

: TOP-CELL ( N --- )
( displays  player stream creature )
      DUP 255 = IF DROP 2 SPACES ELSE ( nothing there? )
        DUP 3 AND 1+ 1 = IF 1 ELSE 2 THEN TEXTCOLOR
        DUP 32 AND IF ." *" ELSE SPACE THEN
        4/ 7 AND           ( get creature type       )
        BEGCASE
           CASE 0 OF ." |" ;;
           CASE 1 OF ." W" ;;
           CASE 2 OF ."  " ;;
           CASE 3 OF ." S" ;;
           CASE 4 OF ." D" ;;
           CASE 5 OF ." E" ;;
           CASE 6 OF ." G" ;;
           CASE 7 OF ." Z" ;;
        ENDCASE
      THEN 0 TEXTCOLOR ;

: BOT-CELL ( n --- )
( displays  wraiths terrain )
    DUP 511 = IF DROP ." ==" ELSE      ( off board?           )
      DUP 255 = IF DROP 2 SPACES ELSE
        DUP 3 AND 1+ 1 = IF 1 ELSE 2 THEN TEXTCOLOR
        DUP 4/ 7 AND DUP 1 = SWAP 7 = OR ( wiz or wraith?      )
          IF 64 / .  SPACE ELSE         ( yes, print strength  )
          64 / BEGCASE
             CASE 0 OF 2 SPACES ;;  ( else print terrain type  )
             CASE 1 OF ."  L"  ;;
             CASE 2 OF ."  M"  ;;
             CASE 3 OF 2 SPACES ;;
          ENDCASE
        THEN
      THEN
    THEN 0 TEXTCOLOR ;

: .CELL ( x y --- ) 2DUP CELL@ -ROT
    2* OVER ODD IF 1+ THEN
    SWAP _CELLW * 1+ SWAP 2DUP GOTOXY
    ROT DUP TOP-CELL -ROT 1+ GOTOXY BOT-CELL  ;

: .UCELL  ( x y --- x y ) UP  .CELL ;
: .ULCELL ( x y --- x y ) UPL .CELL ;
: .URCELL ( x y --- x y ) UPR .CELL ;
: .LLCELL ( x y --- x y ) LOL .CELL ;
: .LRCELL ( x y --- x y ) LOR .CELL ;
: .LCELL  ( x y --- x y ) LO  .CELL ;

: DRAW-BOARD PAGE
   _HEIGHT 0 DO
      _WIDTH 0 DO

        I J _WIDTH * + _BOARD + C@
        ." /" TOP-CELL ." \"
        I J 1- DUP 0 >= IF _WIDTH * + 1+ _BOARD + C@
          ELSE DROP DROP 511 THEN BOT-CELL

      2 +LOOP ." /" CR ." \"

      _WIDTH 0 DO

        I J _WIDTH * + _BOARD + C@ BOT-CELL
        I J _WIDTH * + 1+ _BOARD + C@
        ." /" TOP-CELL ." \"

      2 +LOOP CR
   LOOP
;

( *--------------------------------------------------------* )
( * Utility subroutines:                                   * )

: DEBOUNCE BEGIN BUTTONS OR 0= UNTIL ;

: PNT-CELL ( --- x y )

    DO-MOUSE  ( get mouse coordinates )
    SWAP 24 / ( calc x ) SWAP
    OVER ODD IF ( if x is odd then add 8 to y ) 8 - THEN
    16 / ( calc y ) ;

( *--------------------------------------------------------* )

: SUPPORT-CASE ( cell --- )
     DUP 32 AND 0> 2* SWAP DUP ( 2 points for stream )
     4/ 7 AND
     BEGCASE
        CASE 0 OF ( dolmen ) DROP ;;
        CASE 1 OF ( wraith ) 64 / + ;;
        CASE 2 OF ( nothing ) DROP ;;
        CASE 3 OF ( sentry ) DROP ;;
        CASE 4 OF ( demon ) DROP 1 + ;;
        CASE 5 OF ( elemental ) DROP 1 + ;;
        CASE 6 OF ( golem ) DROP 1 + ;;
        CASE 7 OF ( wiz ) 64 / 3 + + ;;
     ENDCASE
;

: CALC-SUPPORT ( cell --- n )
     DUP 255 <> IF
       DUP 3 AND 1+ I' = IF
         SUPPORT-CASE
       ELSE DROP 0 THEN
     ELSE DROP 0 THEN
;

: GET-SUPPORT  ( player x y --- n )
     ROT >R ( save player on stack )

     ( do surrounding hexes )
           2DUP 1- CELL@ CALC-SUPPORT ( upper )
        >R 2DUP 1+ CELL@ R> SWAP CALC-SUPPORT + ( lower )
        >R OVER ODD IF ( odd x? )
             2DUP SWAP 1- SWAP CELL@ R>
             SWAP CALC-SUPPORT + ( upper left )
          >R 2DUP SWAP 1+ SWAP CELL@ R>
             SWAP CALC-SUPPORT + ( upper right )
          >R 2DUP 1+ SWAP 1- SWAP CELL@ R>
             SWAP CALC-SUPPORT + ( lower left )
          >R      1+ SWAP 1+ SWAP CELL@ R>
             SWAP CALC-SUPPORT + ( lower right )
        ELSE ( even )
             2DUP 1- SWAP 1- SWAP CELL@ R>
             SWAP CALC-SUPPORT + ( upper left )
          >R 2DUP 1- SWAP 1+ SWAP CELL@ R>
             SWAP CALC-SUPPORT + ( upper right )
          >R 2DUP SWAP 1- SWAP CELL@ R>
             SWAP CALC-SUPPORT + ( lower left )
          >R      SWAP 1+ SWAP CELL@ R>
             SWAP CALC-SUPPORT + ( lower right )
        THEN  R> DROP ;

: OTHER-PLAYER ( --- n )
   _PLAYER @ 1 = IF 2 ELSE 1 THEN ;

: .PLAYER 0 24 GOTOXY ."  Wizard " _PLAYER @ . ." : " ;

( *--------------------------------------------------------* )
( * Game playing subroutines:                              * )

: GET-KEY ."  PRESS ANY KEY " 27 EMIT ." K" KEY DROP ;

: ATTACK-OK? ( x y --- cell f )
   CELL@ DUP 255 <> OVER 3 AND 1+ _PLAYER @ = AND ;

: ATTACKABLE ( x y --- cell f )
   CELL@ DUP 255 <> OVER 3 AND 1+ OTHER-PLAYER = AND ;

: .WHICH? .PLAYER ." Attack which cell?" 27 EMIT ." K" ;

: .NO-ATTACK .PLAYER
       ." Cannot attack from this cell." GET-KEY ;

: .CANT-ATTACK .PLAYER
       ." Cannot attack this cell." GET-KEY ;

( *---------------------------------------------------------* )
( * Odds:                                                   * )

: DO-ODDS
  .PLAYER ." Attack from which cell?" 27 EMIT ." K"
  0 24 GOTOXY
  PNT-CELL ATTACK-OK?
  IF ( wrong player or bad cell? )

    ( all values in following CASE are points added on
       top of support values: )

    DUP 32 AND 0> SWAP
      DUP 4/ 7 AND ( if stream or valid )

      BEGCASE
         CASE 0 OF ( dolmen ) DROP 0
                 ." A Dolmen can't attack" ;;
         CASE 1 OF ( wraith ) DROP 1 ;;
         CASE 2 OF ( stream ) DROP DUP ;;
         CASE 3 OF ( sentry ) DROP 0 ;;
         CASE 4 OF ( demon  ) DROP 3 ;;
         CASE 5 OF ( elemental ) DROP 0
            ." Elementals destroy all energy creatures" ;;
         CASE 6 OF ( golem ) DROP 0
             ." Golems can only attack dolmens" ;;
         CASE 7 OF ( wizard ) DROP 1 ;;
      ENDCASE

      DUP _ATTACK ! +
      IF ( stream or attacking space )

        .PLAYER .WHICH?
        OTHER-PLAYER PNT-CELL 2DUP

        2DUP _PLAYER @ -ROT GET-SUPPORT _ATTACK +!

        0 24 GOTOXY ATTACKABLE IF

          DUP 32 AND 0> 2* SWAP
          DUP 4/ 7 AND ( if stream or valid )

          BEGCASE
             CASE 0 OF ." Can't attack a dolmen." DROP 0 ;;
             CASE 1 OF ( wraith ) 64 / ;;
             CASE 2 OF ( nothing ) DROP 0 ;;
             CASE 3 OF ( sentry ) DROP 0 ;;
             CASE 4 OF ( demon ) DROP 3 ;;
             CASE 5 OF ( elemental ) DROP 3 ;;
             CASE 6 OF ( golem ) DROP 3 ;;
             CASE 7 OF ( wiz ) 64 / 3 + ;;
          ENDCASE

          + DUP _DEFEND !

          IF GET-SUPPORT _DEFEND +!
            ." Attacker's strength: "
            _ATTACK @ . 2 SPACES
            ." Defender's strength: "
            _DEFEND @ .               GET-KEY
          ELSE GET-KEY DROP
          THEN

        ELSE .CANT-ATTACK
         2DROP 2DROP
        THEN

      ELSE
        GET-KEY
      THEN
  ELSE .NO-ATTACK
         DROP
  THEN ;

( *---------------------------------------------------------* )
( * Attack routines:                                        * )

: WHICH-MAGIC _PLAYER @  1 = IF _MAGIC1 ELSE _MAGIC2 THEN ;

: CHECK-MAGIC ( n --- ) WHICH-MAGIC
     @ > IF R> .PLAYER ." Not enough magic points." GET-KEY
     THEN ;

: ADJ-MAGIC ( n --- ) WHICH-MAGIC +! DRAW-STATUS ;

: REMOVE-STREAM ( cell1 --- cell2 )
      DUP _STRMBIT 252 XOR AND 8 = IF
      DROP 255
      ELSE DUP _STRMBIT 255 XOR AND SWAP 3 AND OR THEN ;

: REMOVE-WIZ ( cell1 --- cell2 )
      DUP 64 / 0 = IF DROP 255
      ELSE 3 AND _WIZ0 OR THEN ;

: REMOVE-WRAITH ( cell1 --- cell2 )
      DUP 64 / 1 > IF ( wraiths to remove? )
        64 -
      ELSE
        DUP 4/ 7 AND 7 = IF ( wizard in this square? )
          REMOVE-WIZ
        ELSE 255 THEN
      THEN ;

: REMOVE-ATTACKER ;

: REMOVE-DEFENDER _VICTIMX @ _VICTIMY @ CELL@ DUP

     ( remove a stream if there's one there. )
     32 AND IF REMOVE-STREAM _VICTIMX @ _VICTIMY @ CELL!

     ( remove a wraith if there's one there. )
     ELSE DUP 4/ 7 AND DUP 1 = SWAP 7 = OR IF
        REMOVE-WRAITH

        ELSE DROP 255
        THEN

       _VICTIMX @ _VICTIMY @ CELL!
     THEN _VICTIMX @ _VICTIMY @ .CELL ;

VARIABLE _LOCAL1 VARIABLE _LOCAL2 VARIABLE _LOCAL3
VARIABLE _LOCAL4

: DO-BATTLE RANDOM _ATTACK @ 6 * MOD
            RANDOM _DEFEND @ 6 * MOD
            <
            IF .PLAYER ." Loses!" REMOVE-ATTACKER
            ELSE REMOVE-DEFENDER
              .PLAYER ." Wins!" THEN
            GET-KEY ;

: NEXT-TO? ( x1 y1 x2 y2 --- f )
     _LOCAL4 !  _LOCAL3 !  _LOCAL2 !  _LOCAL1 !
     _LOCAL1 @ _LOCAL3 @ =   ( x1=x2 & y+-1 )
     _LOCAL2 @ _LOCAL4 @ - ABS 2 < AND
     _LOCAL2 @ _LOCAL4 @ =   ( y1=y2 & x+-1 )
     _LOCAL1 @ _LOCAL3 @ - ABS 2 < AND OR
     _LOCAL1 @ ODD IF
       _LOCAL2 @ 1+ _LOCAL4 @ = ( y1+1=y2 & x+-1 )
       _LOCAL1 @ _LOCAL3 @ - ABS 2 < AND OR
     ELSE
       _LOCAL2 @ 1- _LOCAL4 @ = ( y1-1=y2 & x+-1 )
       _LOCAL1 @ _LOCAL3 @ - ABS 2 < AND OR
     THEN ;

: ATTACK-MATRIX ( cell --- n )
     ( assumes cell has a valid attacking cell )
     ( no extra bonus for stream.  It will be counted later )
     ( Values are adjusted to be attack-support value )
     DUP 4/ 7 AND
     BEGCASE
        CASE 0 OF ( dolmen ) DROP 0 ;;
        CASE 1 OF ( wraith ) 64 / ;;
        CASE 2 OF ( stream only ) DROP 0 ;;
        CASE 3 OF ( sentry ) DROP 0 ;;
        CASE 4 OF ( demon  ) DROP 3 ;;
        CASE 5 OF ( elemental ) DROP 3 ;;
        CASE 6 OF ( golem  ) DROP 3 ;;
        CASE 7 OF ( wiz    ) 64 / 3 + ;;
     ENDCASE
     _PLAYER @ _VICTIMX @ _VICTIMY @ GET-SUPPORT + 1+ ;

: DEFEND-MATRIX ( cell --- n )

     DUP 32 AND 0> 2* SWAP
     DUP 4/ 7 AND
     BEGCASE
        CASE 0 OF ( dolmen ) DROP 0 ;;
        CASE 1 OF ( wraith ) 64 / ;;
        CASE 2 OF ( stream only ) DROP 2 ;;
        CASE 3 OF ( sentry ) DROP 0 ;;
        CASE 4 OF ( demon ) DROP 3 ;;
        CASE 5 OF ( elemental ) DROP 3 ;;
        CASE 6 OF ( golem ) DROP 3 ;;
        CASE 7 OF ( wiz ) 64 / 3 + ;;
    ENDCASE + DUP _DEFEND !
    IF
      OTHER-PLAYER _VICTIMX @ _VICTIMY @ GET-SUPPORT
      _DEFEND +! _DEFEND @
    THEN ;

: STREAM-ATTACK ( x y cell --- )
   _CELL !  2DUP _AGGRESSY ! _AGGRESSY !

   .WHICH? PNT-CELL 2DUP ATTACKABLE

   IF >R 2DUP _VICTIMY !  _VICTIMX !

      NEXT-TO? R> SWAP ( --- target-cell f )
      IF

        DEFEND-MATRIX DUP IF
           .PLAYER ." Defender's strength: " . 2 SPACES
           ." Attacker's strength: "
           _CELL @ ATTACK-MATRIX DUP _ATTACK ! .
           ."  Return to battle"
           KEY 13 = IF DO-BATTLE -1 ADJ-MAGIC THEN

        ELSE DROP .CANT-ATTACK THEN
      ELSE DROP THEN
   ELSE 3DROP 2DROP .CANT-ATTACK THEN ;

: DOLMEN-ATTACK ( x y cell --- )
     3DROP .PLAYER ." Dolmens can't attack." GET-KEY ;

: WRAITH-ATTACK ( x y cell --- )
     3DROP ;

: NO-ATTACK 3DROP .NO-ATTACK ;

: DEMON-ATTACK ( x y cell --- )
     3DROP ;

: ELEMENTAL-ATTACK ( x y cell --- )
     3DROP ;

: GOLEM-ATTACK ( x y cell --- ) DROP
    .PLAYER ." Attack which dolmen?" 27 EMIT ." K"
    ( allow the cell if it is the other player's dolmen )
    PNT-CELL 2DUP CELL@ DUP 3 AND OTHER-PLAYER 1- = SWAP
    4/ 0= AND IF
      NEXT-TO? IF
        _LOCAL1 @ _LOCAL2 @ CELL@ ( move golem onto dolmen )
        _LOCAL3 @ _LOCAL4 @ CELL!
        255 _LOCAL1 @ _LOCAL2 @ CELL!
        _LOCAL1 @ _LOCAL2 @ .CELL
        _LOCAL3 @ _LOCAL4 @ .CELL             .S CR
 QUIT   UCELL@  REMOVE-WRAITH -ROT UCELL!  .UCELL
        URCELL@ REMOVE-WRAITH -ROT URCELL! .URCELL
        LRCELL@ REMOVE-WRAITH -ROT LRCELL! .LRCELL
        LLCELL@ REMOVE-WRAITH -ROT LLCELL! .LLCELL
        LCELL@  REMOVE-WRAITH -ROT LCELL!  .LCELL
        ULCELL@ REMOVE-WRAITH -ROT ULCELL! .ULCELL
        2DROP
      ELSE
        .CANT-ATTACK
      THEN
    ELSE .CANT-ATTACK THEN ;

: WIZ-ATTACK ( x y cell --- )
     3DROP ;

: DO-ATTACK  1 CHECK-MAGIC
     .PLAYER ." Attack from which cell?" 27 EMIT ." K"
     PNT-CELL 2DUP ATTACK-OK? IF
       DUP 32 AND 0> IF
         STREAM-ATTACK
       ELSE DUP 4/ 7 AND
         BEGCASE
            CASE 0 OF DOLMEN-ATTACK ;;
            CASE 1 OF WRAITH-ATTACK ;;
            CASE 2 OF NO-ATTACK ;;
            CASE 3 OF NO-ATTACK ;;
            CASE 4 OF DEMON-ATTACK ;;
            CASE 5 OF ELEMENTAL-ATTACK ;;
            CASE 6 OF GOLEM-ATTACK ;;
            CASE 7 OF WIZ-ATTACK ;;
         ENDCASE
       THEN
     ELSE 3DROP .NO-ATTACK THEN ;

( *---------------------------------------------------------* )
( *  Spells:                                                * )

: STREAM? ( cell player --- f )
      OVER 3 AND 1+ =
        SWAP 32 AND 0>
      AND ;

: IN-RING? ( x y --- f )
    _PLAYER @ >R
    2DUP 1- CELL@ R@ STREAM? >R
    2DUP 1+ CELL@ I' STREAM? R> + >R
    2DUP SWAP 1- SWAP CELL@ I' STREAM? R> + >R
    2DUP SWAP 1+ SWAP CELL@ I' STREAM? R> + >R
    OVER ODD IF
      2DUP 1+ SWAP 1- SWAP CELL@ I' STREAM? R> + >R
           1+ SWAP 1+ SWAP CELL@ I' STREAM? R> + >R
    ELSE ( even )
      2DUP 1- SWAP 1- SWAP CELL@ I' STREAM? R> + >R
           1- SWAP 1+ SWAP CELL@ I' STREAM? R> + >R
    THEN
  R> 6 =
  R> DROP ;

: ADJ? ( x y --- f )
    _PLAYER @ >R
    2DUP 1- CELL@ 3 AND 1+ R@ = >R ( upper )
    2DUP 1+ CELL@ 3 AND 1+ I' = R> OR >R ( lower )
    2DUP SWAP 1- SWAP CELL@ 3 AND 1+ I' = R> OR >R
    2DUP SWAP 1+ SWAP CELL@ 3 AND 1+ I' = R> OR >R
    OVER ODD IF
      2DUP 1+ SWAP 1- SWAP CELL@ 3 AND 1+ I' = R> OR >R
           1+ SWAP 1+ SWAP CELL@ 3 AND 1+ I' = R> OR >R
    ELSE ( even )
      2DUP 1- SWAP 1- SWAP CELL@ 3 AND 1+ I' = R> OR >R
           1- SWAP 1+ SWAP CELL@ 3 AND 1+ I' = R> OR >R
    THEN
  R> R> DROP ;

: .NO-GOOD .PLAYER ." Something is already in that cell."
      GET-KEY ;

: .NO-RING .PLAYER ." No ring is present there." GET-KEY ;

: .NO-STREAM .PLAYER ." No stream is present there." GET-KEY ;

( *-----------------------------------------------------* )
( * Summon creatures:                                   * )

: CALL-CREATURE ( creature cost --- )
    _COST !  _CREATURE !
    ."  where?" 27 EMIT ." K"
    PNT-CELL 2DUP CELL@ 255 = IF
       2DUP IN-RING? IF
         2DUP
         _CREATURE @ _PLAYER @ 1- OR -ROT CELL!
         _COST @ ADJ-MAGIC .CELL
       ELSE 2DROP .NO-RING THEN
    ELSE 2DROP .NO-GOOD THEN ;

: CALL-DEMON 2 CHECK-MAGIC
    .PLAYER ." Summon demon"
    _DEMON -2 CALL-CREATURE ;

: CALL-GOLEM 4 CHECK-MAGIC
    .PLAYER ." Summon Golem"
    _GOLEM -4 CALL-CREATURE ;

: CALL-ELEMENTAL 3 CHECK-MAGIC
    .PLAYER ." Summon Elemental"
    _ELEMENTAL -3 CALL-CREATURE ;

( *-----------------------------------------------------* )

: ADD-STREAM 2 CHECK-MAGIC
    .PLAYER ." Place magic stream where? " 27 EMIT ." K"
    PNT-CELL 2DUP CELL@ DUP 255 = SWAP
    DUP 3 AND 1+ _PLAYER @ = SWAP 4/ 7 AND 1 = AND OR

    IF
      2DUP ADJ? IF
        2DUP CELL@ 255 = IF
           2DUP _PLAYER @ 1- _STREAM OR -ROT CELL!
        ELSE 2DUP 2DUP CELL@ _STRMBIT OR -ROT CELL!
        THEN
        .CELL -2 ADJ-MAGIC
      ELSE .PLAYER ." Place magic stream "
          ." adjacent to friendly hexes." 2DROP GET-KEY
      THEN

    ELSE
      .NO-GOOD
    THEN ;

: KILL-STREAM
    .PLAYER ." Remove which magic stream?" 27 EMIT ." K"
    PNT-CELL 2DUP CELL@ _PLAYER @ STREAM? IF
       2DUP 2DUP CELL@ 252 _STRMBIT XOR AND DUP 8 = IF
         DROP 255 ELSE _PLAYER @ 1- OR THEN
       -ROT CELL! .CELL
       1 ADJ-MAGIC
    ELSE 2DROP .NO-STREAM THEN ;

( *-------------------------------------------------------* )

: .NO-MOVE .PLAYER ." Cannot move this piece." GET-KEY ;

: MOVE-WHERE? .PLAYER ." Move where?" 27 EMIT ." K"
   PNT-CELL ;

: STREAM-IT ;

: MOVE-ONCE ( x y --- ) MOVE-WHERE? 2DUP CELL@ 255 = IF
    NEXT-TO? IF _LOCAL1 @ _LOCAL2 @ 2DUP CELL@ ( get marker )
      -ROT ( hide cell )
       255 -ROT CELL! ( clear old cell )
      _LOCAL3 @ _LOCAL4 @
      CELL!  ( store in new location )
      _LOCAL1 @ _LOCAL2 @ .CELL ( update display )
      _LOCAL3 @ _LOCAL4 @ .CELL
    THEN
   THEN ;

: DO-MOVEMENT
    .PLAYER ." Move which piece?" 27 EMIT ." K"
    PNT-CELL 2DUP CELL@ DUP 3 AND _PLAYER @ 1- =
    IF
      4/ 7 AND BEGCASE
        CASE 0 OF ( dolmen ) .NO-MOVE ;;
        CASE 1 OF ( wraith ) .NO-MOVE ;;
        CASE 2 OF ( nothing ) .NO-MOVE ;;
        CASE 3 OF ( sentry ) .NO-MOVE ;;
        CASE 4 OF ( demon ) STREAM-IT ;;
        CASE 5 OF ( elemental ) STREAM-IT ;;
        CASE 6 OF ( golem ) MOVE-ONCE ;;
        CASE 7 OF ( wiz ) .NO-MOVE ;;
      ENDCASE
    ELSE .NO-MOVE
    THEN ;

( *-------------------------------------------------------* )

: MAGIC-HELP 32
    BEGIN DROP 0 24 GOTOXY
    ." COSTS: "
    ." Add magic stream>2  Remove magic stream>-1  Demon>2 "
    ." --space for more" 27 EMIT ." K"
    KEY DUP 32 = IF   0 24 GOTOXY
    ." COSTS: "
    ." Elemental>3  Golem>4  Lava>4  Marsh>4  Ground>4 "
    ." --space for more" 27 EMIT ." K"
    KEY THEN
    32 <> UNTIL ;

: CHOOSE-SPELL ( key --- f )
    BEGCASE
      CASE 65 ( A ) OF ADD-STREAM 0 ;;
      CASE 67 ( C ) OF MAGIC-HELP 0 ;;
      CASE 68 ( D ) OF CALL-DEMON 0 ;;
      CASE 69 ( E ) OF CALL-ELEMENTAL 0 ;;
      CASE 71 ( G ) OF CALL-GOLEM 0 ;;
      CASE 76 ( L ) OF 0 ;;
      CASE 77 ( M ) OF 0 ;;
      CASE 82 ( R ) OF KILL-STREAM 0 ;;
      CASE 83 ( S ) OF 0 ;;
      ELSECASE 1 ;;
    ENDCASE ;

: DO-SPELL
  BEGIN 32
    BEGIN
    DROP  DRAW-STATUS
    .PLAYER
    ." A)dd magic stream  R)emove magic stream  D)emon "
    ." --space for more" 27 EMIT ." K"
    KEY DUP 32 = IF
    DROP .PLAYER
    ." E)lemental G)olem L)ava M)arsh S)Ground "
    ." Q)uit C)osts"
    ." --space for more" 27 EMIT ." K"
    KEY THEN
    DUP 32 <> UNTIL

    223 AND ( convert key to uppercase )
    CHOOSE-SPELL
  UNTIL
;

: DO-MOVE ( key --- )
    223 AND  ( convert key to uppercase )
    BEGCASE
      CASE 77 ( M ) OF DO-MOVEMENT 0 ;;
      CASE 83 ( S ) OF DO-SPELL 0 ;;
      CASE 65 ( A ) OF DO-ATTACK 0 ;;
      CASE 79 ( O ) OF DO-ODDS 0 ;;
      CASE 80 ( P ) OF 1 ;;
      CASE 81 ( Q ) OF QUIT ;;
      ELSECASE 7 EMIT 0 ;;
    ENDCASE
;

: START-1  _DOLMEN1 @ 3 * _MAGIC1 +! 1 _PLAYER ! ;
: START-2  _DOLMEN2 @ 3 * _MAGIC2 +! 2 _PLAYER ! ;

: GET-MOVE

   BEGIN
     .PLAYER
     ."  M)ove  S)pell  A)ttack  O)dds  P)ass  Q)uit >> "
     27 EMIT ." K"

     KEY DO-MOVE

   UNTIL ;

( *------------------------------------------------------* )

: WIZARDS

    DECIMAL
    INIT DRAW-BOARD

    BEGIN
      START-1
      DRAW-STATUS
      GET-MOVE
      START-2
      DRAW-STATUS
      GET-MOVE
    0 UNTIL
;

QUIT

