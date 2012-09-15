
( ********************************************************* )
( *  Nick's contribution to the editor:                   * )
( *-------------------------------------------------------* )
( * FILE: EDFEN.4TH                                       * )
( ********************************************************* )

DECIMAL

( *  funnybox's data structure:                          * )

CREATE TESTBAR
    4 , 3 , 63 , 3 , 152 , 20 , 20 ,

CREATE F$
    3 , 7 , 3 , 3 , 2 , ," Fusion Program Editor v2.0"

CREATE BOX2
    1 , 2 , 1 , _SOLID A, 1 , 62 , 2 , 66 , 23 ,
    1 , TESTBAR A,

CREATE BOX3
    1 , 2 , 1 , _SOLID A, 1 , 5 , 13 , 30 , 23 , 0 ,

CREATE FINDB
    2 , 1 , 36 , 19 ,
    8 C, 32 C, 2 C, 32 C, 70 C, 73 C, 78 C, 68 C, 32 C,

CREATE BFINDB
    2 , 1 , 48 , 19 ,
    8 C, 32 C, 1 C, 32 C, 70 C, 73 C, 78 C, 68 C, 32 C,

CREATE RPLCB
    2 , 1 , 36 , 21 ,
    ,"  REPLACE "

CREATE PRINTB
    2 , 1 , 39 , 9 ,
    ,"  PRINT MENU "

CREATE LOADB
    2 , 1 , 44 , 7 ,
    ,"  LOAD  "

CREATE SAVEB
    2 , 1 , 44 , 5 ,
    ,"  SAVE  "

CREATE BOX4$
    3 , 33 , 14 , 3 , 2 ,
    ," Find and Replace a String"

CREATE FIND$
    6 , 33 , 16 , 1 , 3 ,
    ," FIND                      " 0 C, 0 C,

CREATE FIND$
    6 , 33 , 16 , 1 , 3 ,
    ," FIND                      " 0 C, 0 C,

CREATE REPLACE$
    6 , 33 , 17 , 1 , 3 ,
    ," REPLACE                   " 0 C, 0 C,

CREATE BOX4
    1 , 2 , 1 , _SOLID A, 1 , 32 , 13 , 60 , 23 ,
    6 , BOX4$ A, FINDB A, BFINDB A, RPLCB A, FIND$ A,
    REPLACE$ A,

CREATE BIGBOX
    1 , 2 , 1 , _SOLID A, 1 , 5 , 2 , 60 , 12 ,
    7 , F$ A, PRINTB A, BOX2 A, BOX3 A, BOX4 A, LOADB A, SAVEB A,

( ********************************************************* )
( * the funnybox itself:                                  * )

VARIABLE _TMARK

: GETLEN ( -- n ) _TOTAL @ BUFFER - _CW @ / 1- ;
: GETMARK ( -- n ) _TMARK @ BUFFER - _CW @ / 1+ ;

: SHOWPRAMS
    27 EMIT ." bC" 27 EMIT ." cb"
    23 7 GOTOXY GETLEN 1+ 4 .R ( Length )
    23 8 GOTOXY ORG _TOTAL @ - _CW @ / 5 .R ( space remaining )
    35 6 GOTOXY
    _OLDMARK @ BUFFER -
    _CW @ / _Y @ + 1+ . ."    "  ( place )
    31 5 GOTOXY GETMARK . ."    "               ( slider )
;

: SETSLIDER   ( Slider is 152/304 pixels tall )
    152 YADJ TESTBAR 16 + ! ( set bar height per resolution )
      3 YADJ TESTBAR 12 + !
    3800 YADJ ( 25 * 152 )
    GETLEN ( get length in lines )
    / ( calced height of slider ) 152 YADJ MIN 8 YADJ MAX
     DUP TESTBAR 24 + ! ( store height )
    GETMARK 152 YADJ * GETLEN / SWAP 152 YADJ SWAP - MIN
     TESTBAR 20 + !
    TESTBAR VBAR DROP ;

: FIXBAR _OLDMARK @ _TMARK ! SHOWPRAMS SETSLIDER ;

: DRAWBOXES
   SETSLIDER
   BIGBOX DRAWTREE
  1 TEXTCOLOR 2 BACKCOLOR
  7 5 GOTOXY
  ." Slider points to line:"
  7 6 GOTOXY
  ." Current place in file: line"
  7 7 GOTOXY
  ." Length of file:      lines"
  7 8 GOTOXY
  ." Space remaining:      lines"
  7 9 GOTOXY
  ." Block start: line"
  7 10 GOTOXY
  ." Block end: line"
  7 11 GOTOXY
  ." Indent is OFF"
  3 TEXTCOLOR 2 BACKCOLOR 30 11 GOTOXY .DATE

  7 13 GOTOXY
  ." f1 - Block start"
  7 14 GOTOXY
  ." ^f1 - Select none"
  7 15 GOTOXY
  ." f2 - Block end"
  7 16 GOTOXY
  ." f3 - Copy block"
  7 18 GOTOXY
  ." f4 - Paste block"
  7 17 GOTOXY
  ." ^f3 - Delete block"
  7 19 GOTOXY
  ." f6 - Ins/replace"
  7 20 GOTOXY
  ." f7 - Set mark"
  7 21 GOTOXY
  ." f9 - Start of file"
  7 22 GOTOXY
  ." f10 - End of file"
  SHOWPRAMS
;

: <PAGE
     _TMARK @ _CW @ 25 * -
     BUFFER MAX _TMARK !
     SHOWPRAMS SETSLIDER ;

: PAGE>
     _TMARK @ _CW @ 25 * +
     _TOTAL @ _CW @ 25 * - MIN _TMARK !
     SHOWPRAMS SETSLIDER ;

: FIXLINE
     TESTBAR 20 + @ ( get new slider Y )
     GETLEN * 152 YADJ / _CW @ * BUFFER + _TMARK !
     SHOWPRAMS SETSLIDER ;

: CHKSLIDE
     _BAR @
       BEGCASE
         CASE 1 OF <PAGE ;;
         CASE 2 OF FIXLINE ;;
         CASE 3 OF PAGE> ;;
         ELSECASE ;;
       ENDCASE ;

: LOADBOX " *.*" "  Load which file? " FSEL
    _FCODE @ IF
    FILE$ 20 + COUNT GOGETIT THEN ;

: SAVEBOX " *.*" "  Save to what filename? " FSEL
    _FCODE @ IF
    FILE$ 20 + COUNT GOPUTIT THEN ;

: CHECK-PR _OBJ @ 1 = IF PRINTBOX R> DROP THEN
           _OBJ @ 5 = IF LOADBOX  R> DROP THEN
           _OBJ @ 6 = IF SAVEBOX  R> DROP THEN ;

: DEBOUNCE-MOUSE BEGIN BUTTONS OR 0= UNTIL ;

: FUNNYBOX DEBOUNCE-MOUSE
       _OLDMARK @ _TMARK !
       DRAWBOXES TOSMOUSE
       BEGIN
         MOUSEXY 60SYNCH _MBUFF UNSPRITE
                         _MOUSE _MBUFF SPRITE
         BUTTONS IF
          _MBUFF UNSPRITE BIGBOX GOTCLICK
          _BOX @
            BEGCASE
              CASE 1 OF ( print BOX ) CHECK-PR ;;
              CASE 2 OF ( slider ) CHKSLIDE ;;
              CASE 3 OF ( help ) ;;
              CASE 4 OF ( find ) ;;
              ELSECASE ;; ( outside )
            ENDCASE
         THEN

         3 TEXTCOLOR 2 BACKCOLOR 45 11 GOTOXY .TIME

         ?KEY IF _MBUFF UNSPRITE
             KEY DUP 354 = SWAP 353 = IF FIXBAR THEN
         ELSE 0 THEN
       OR UNTIL C-ON _MBUFF UNSPRITE
       _TMARK @ BUFFER MAX _OLDMARK !
       DEBOUNCE-MOUSE ;

QUIT


