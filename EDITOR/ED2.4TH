DECIMAL .(      The editor mark II )

( *********************************************************** )
( *                                                         * )
( *  Fusion Forth Editor v2.0 by Don Palmer & Nick Porcino  * )
( *                                                         * )
( *********************************************************** )

( ************* )
( * Variables * )
( ************* )

VARIABLE _BLOCK1     VARIABLE _BLOCK2     VARIABLE _TEMP1
VARIABLE _Y2         VARIABLE _BLKBUF
VARIABLE _BUFLEN     VARIABLE _REP

4718592 CONSTANT CURSUP       5242880 CONSTANT CURSDWN
4915200 CONSTANT CURSLFT      5046272 CONSTANT CURSRGT
4718648 CONSTANT PAGUP        5242930 CONSTANT PAGDWN
5046326 CONSTANT TXTRGT       4915252 CONSTANT TXTLFT
3866624 CONSTANT BLST         3932160 CONSTANT BLED
4390912 CONSTANT TXTSTART     4456448 CONSTANT TXTEND
6422528 CONSTANT HELP          917512 CONSTANT BAKSPC
6356992 CONSTANT UNDO         4194304 CONSTANT REPFLG
5439615 CONSTANT DELK          983049 CONSTANT TAB
1048576 CONSTANT CLR          5439519 CONSTANT DELN
5373952 CONSTANT INSLN        7471117 CONSTANT NRKEY
1835021 CONSTANT SPLIT        1179653 CONSTANT WSUP
2949144 CONSTANT WSDN         2031635 CONSTANT WSLT
2097156 CONSTANT WSRT         3997696 CONSTANT COPY
4063232 CONSTANT PASTE        5636096 CONSTANT CUT
5505024 CONSTANT BLNIL        2228231 CONSTANT WSDELK

VARIABLE UNDOBUF 90 ALLOT
VARIABLE REPBUF 170 ALLOT

( ************************* )
( * Some vt-52 primitives * )
( ************************* )

: ESC ( --- ) 27 EMIT ; ( esc output )
: C-ON ( --- ) ESC 101 EMIT ; ( cursor on )
: C-OFF ( --- ) ESC 102 EMIT ;
: WRAP ( --- ) ESC 118 EMIT ; ( wrap line mode )
: UNWRAP ( --- ) ESC 119 EMIT ; ( truncate line mode )
: R-ON ( --- ) ESC 112 EMIT ;
: R-OFF ( --- ) ESC 113 EMIT ;

( ************************** )
( * The editor subroutines * )
( ************************** )

: NEW ( --- )
    BUFFER _MARK !
    BUFFER _CW @ + _TOTAL !  ( make file one line long )
    BUFFER _CW @ BL FILL     ( clear one line of text  )
    _BLSTART 0!              ( clear the block         )
    _BLEND   0!
    _BLKLEN  0! ;

: BEEP ( --- ) ( ring the bell, win a prize! )
  7 EMIT ;

: KEY2 ( --- KEY# )
  2 L>W 2 L>W 2 BIOS ;

: LINES ( --- )
  3 SETCOLOR
  _IW @ 8 * 4 + DUP >R 0 R> 199 YADJ LINE
  _IW @ _CW @ + 1 + 8 * 4 + DUP >R 0 R> 199 YADJ LINE
  _REP @ IF
       0 SETCOLOR
  THEN
  _IW @ _CW @ + 1 + 8 * 7 + DUP >R 0 R> 199 YADJ LINE ;

: POS ( --- ) ( nil )
  _X @ _Y @ GOTOXY ; ( update cursor )

: BOUNDS ( --- ) ( _mark )
  _MARK @ _TOTAL @ _CW @ - MIN ( no higher than 1 line less )
  BUFFER MAX ( no lower than the start of the buffer )
  _MARK ! ; ( store the bounded value of _mark )

: LEGAL ( --- flag ) ( nil )
  _MARK @ _TOTAL @ < ; ( is this a legally printable line? )

: LINEBYTE ( --- ADDR )
  _OLDMARK @ _Y @ _CW @ * + ;

: CHARBYTE ( --- ADDR )
  LINEBYTE _X @ _IW @ - 1 - + ;

: CURSORBOUND ( --- )
  LINEBYTE _TOTAL @ >= IF
       _TOTAL @ _OLDMARK @ - _CW @ / 1 - 0 MAX _Y !
  THEN
  _IW @ 1 + _X @ MAX _X ! ;

: >UNDO ( --- )
  LINEBYTE UNDOBUF _CW @ CMOVE
  REPBUF 165 BLANKS ;

: WRTLINE ( --- )
  _IW @ 1 + _Y @ GOTOXY
  LINEBYTE _CW @ TYPE
  _IW @ 1 + _Y @ GOTOXY
  _BLSTART @ LINEBYTE <= _BLEND @ LINEBYTE >= AND
  IF R-ON THEN
  LINEBYTE _CW @ -TRAILING 1 MAX TYPE R-OFF ;

: TXTLINE  ( --- )
  _IW @ 1 + _Y2 @ GOTOXY
  _BLSTART @ _MARK @ <= _BLEND @ _MARK @ >= AND
  IF R-ON THEN
  _MARK @ _CW @ -TRAILING 1 MAX TYPE R-OFF ;

: RTXTLINE ( --- )
  _IW @ 1 + _Y2 @ GOTOXY
  _BLSTART @ _OLDMARK @ <= _BLEND @ _OLDMARK @ >= AND
  IF R-ON THEN
  _OLDMARK @ _CW @ -TRAILING 1 MAX TYPE R-OFF ;

: NOLINE ( --- )
  _IW @ 1 + _Y2 @ GOTOXY
  174 EMIT ." Blank" 175 EMIT ;

: LIST ( --- ) ( _mark )
  _MARK @ _OLDMARK ! ( top of page marker )
  PAGE C-OFF LINES
  24 0 DO ( lets do up to 24 lines )
       I _Y2 !
       LEGAL ( is this a legal line? )
       IF TXTLINE CR ( yes, lets print it )
            _CW @ _MARK +! ( move to next line )
       ELSE NOLINE
       THEN
  LOOP
  24 _Y2 !
  LEGAL ( is the 25th line legal? )
  IF TXTLINE _CW @ _MARK +! ( yes, print it )
  ELSE NOLINE
  THEN C-ON ;

: REDRAW ( --- )
  _OLDMARK @ _MARK ! LIST ;

: PAGEDOWN ( --- ) ( _mark )
  _CW @ _MARK -! ( redisplay last line )
  ( PAGE ) BOUNDS LIST ( list the next page )
  >UNDO ;

: PAGEUP ( --- ) ( _mark )
  _OLDMARK @ 24 _CW @ * - _MARK ! ( move back 1 page - 1 line )
  ( PAGE ) BOUNDS LIST ( list the previous page )
  >UNDO ;

: CURSORUP ( --- ) ( _mark _oldmark _y )
  _Y @ 1 -
  DUP -1 = _OLDMARK @ _CW @ - BUFFER >= AND
  IF 0 0 GOTOXY ESC 76 EMIT
       _OLDMARK @ _MARK @ - ABS 24 _CW @ * > IF
            _CW @ _MARK -! THEN
       _CW @ _OLDMARK -!
       0 _Y2 !
       RTXTLINE LINES
  THEN 0 MAX _Y !
  >UNDO ;

: CURSORDOWN ( --- ) ( _mark _oldmark _y )
  _Y @ 1 + DUP DUP
  _CW @ * _OLDMARK @ + _TOTAL @ <
  IF 25 =
       IF 0 24 GOTOXY CR
            24 _Y2 !
            TXTLINE LINES
            _CW @ _MARK +! _CW @ _OLDMARK +!
       THEN 24 MIN _Y !
  ELSE DROP DROP
  THEN >UNDO ;

: CURSORLEFT ( --- ) ( _x )
  _X @ 1 - _IW @ 1 + MAX _X ! ; ( move cursor 1 right )

: CURSORRIGHT ( --- ) ( _x )
  _X @ 1 + _CW @ _IW @ + MIN _X ! ; ( move cursor 1 left )

: TXTLEFT ( --- )
  _IW @ 1 + _X ! ;

: TXTRIGHT ( --- )
  _OLDMARK @ _Y @ _CW @ * + _CW @ -TRAILING SWAP DROP
  _IW @ + _X ! CURSORRIGHT ;

: CLOSESPACE ( --- )
  LINEBYTE REPBUF _CW @ CMOVE ( GET FROM ACTUAL TEXT )
  _X @ _IW @ - 1 - 0 > IF
       REPBUF _X @ + _IW @ - 1 - ( SET FROM )
       DUP 1 - ( SET TO )
       160 _X @ _IW @ - 1 - - ( SET LENGTH )
       CMOVE ( MOVE IT ALL TO CLOSE CHARACTER )
       REPBUF LINEBYTE _CW @ CMOVE  ( PUT BACK TO ACTUAL TEXT )
  THEN ;

: BACKSPACE ( --- )
  _REP @ IF
       CLOSESPACE
       ELSE 32 CHARBYTE C!
  THEN CURSORLEFT WRTLINE ;

: BLOCKSTART ( --- )
  _OLDMARK @ _Y @ _CW @ * + _BLSTART !
  _BLEND @ _BLSTART @ < IF
       _BLSTART @ _CW @ + 1 - _BLEND !
  THEN
  REDRAW ;

: BLOCKEND ( --- )
  _OLDMARK @ _Y @ _CW @ * + _CW @ + 1 - _BLEND !
  _BLSTART @ _BLEND @ > _BLSTART @ BUFFER < OR IF
       LINEBYTE _BLSTART !
  THEN
  REDRAW ;

: BLOCKNIL ( --- )
  0 _BLSTART ! 0 _BLEND ! REDRAW ;

: REPFLAG ( --- )
  _REP @ NOT _REP ! LINES ;

: TEXTSTART ( --- )
  BUFFER _MARK ! _X 0! _Y 0! CURSORBOUND LIST >UNDO ;

: TEXTEND ( --- )
  _TOTAL @ _MARK ! _X 0! 24 _Y ! BOUNDS _MARK @
  _OLDMARK ! PAGEUP CURSORBOUND POS >UNDO ;

: SHOWGUK FUNNYBOX
   27 EMIT ." bC" 27 EMIT ." c " REDRAW
   _X @ _Y @ GOTOXY ;

: POSNCURS MOUSEXY GETREZ 2 = IF 16 ELSE 8 THEN / SWAP 8 /
  _IW @ 1+ MAX    _CW @ _IW @ + MIN
  _X ! _Y !
  MOUSEXY SWAP DROP DUP 0= IF CURSORUP THEN
    GETREZ 2 = IF 399 ELSE 199 THEN = IF CURSORDOWN THEN
  CURSORBOUND POS ;

: UNDOIT ( --- )
  UNDOBUF LINEBYTE _CW @ CMOVE
  WRTLINE ;

: DELETE ( --- )
  LINEBYTE REPBUF _CW @ CMOVE ( GET ACTUAL TEXT )
  REPBUF _X @ + _IW @ - ( SET FROM )
  DUP 1 - ( SET TO )
  160 _X @ _IW @ - - ( SET LENGTH )
  CMOVE ( MOVE IT ALL TO CLOSE CHARACTER )
  REPBUF LINEBYTE _CW @ CMOVE  ( PUT BACK TO ACTUAL TEXT )
  WRTLINE ;

: INSERT ( --- )
  LINEBYTE REPBUF _CW @ CMOVE ( GET FROM ACTUAL TEXT )
   REPBUF _X @ + _IW @ - ( SET FROM )
   DUP 1 - SWAP ( SET TO )
   160 _X @ _IW @ - 1 - - ( SET LENGTH )
   CMOVE> ( MOVE IT ALL TO MAKE ROOM FOR ONE CHARACTER )
  REPBUF LINEBYTE _CW @ CMOVE ; ( PUT BACK IN ACTUAL TEXT )

: REP ( CHAR -- CHAR )
  DUP DUP DUP 32 >= SWAP 127 <= AND IF
       _REP @ IF
            INSERT THEN
       CHARBYTE C! CURSORRIGHT WRTLINE
  ELSE DROP
  THEN ;

: TABB ( --- )
  _X @ 5 + 5 / 5 * _IW @ _CW @ + MIN _X ! ;

: 0ADJUST ( --- )
  _BLSTART @ BUFFER <
  _BLEND @ BUFFER <
  OR
  _BLSTART @ ORG >
  _BLEND @ ORG >
  OR
  OR IF
       0 _BLSTART ! 0 _BLEND !
  THEN ;

: INS_ADJUST ( --- ) ( adjust blocks and MARKS )
  LINEBYTE _BLEND @ < IF
       _CW @ _BLEND +!
  THEN
  LINEBYTE _BLSTART @ <= IF
       _CW @ _BLSTART +!
  THEN
  0ADJUST ;

: DEL_ADJUST ( --- )
  LINEBYTE _BLEND @ < IF
       _CW @ _BLEND -!
  THEN
  LINEBYTE _BLSTART @ < IF
       _CW @ _BLSTART -!
  THEN
  _BLSTART @ _BLEND @ > IF
       0 _BLEND ! 0 _BLSTART !
  THEN
  0ADJUST ;

: DELLINE ( --- )
  BUFFER _CW @ + _TOTAL @ < IF
       DEL_ADJUST
       LINEBYTE  ( destination )
       DUP _CW @ + ( source )
       SWAP ( put in right order )
       OVER _TOTAL @ SWAP - ( number of bytes to move )
       CMOVE ( move buffer down )
       _CW @ _TOTAL -! ( move down end of buffer )
       ESC 77 EMIT 24 _Y2 ! _CW @ _MARK -!
       LEGAL IF
            TXTLINE _CW @ _MARK +!
       ELSE NOLINE
       THEN LINES >UNDO
  ELSE BEEP
  THEN ;

: LINEBLANK ( --- )
  LINEBYTE _CW @ 32 FILL ; ( blank the current line )

: INSLINE ( --- )
  INS_ADJUST
  LINEBYTE ( source )
  DUP _CW @ + ( destination )
  OVER _TOTAL @ SWAP - ( number of bytes to move )
  CMOVE> ( move buffer up )
  _CW @ _TOTAL +! ( move up end of buffer )
  _MARK @ _OLDMARK @ - 25 _CW @ * < IF ( less than full page? )
     _CW @ _MARK +! ( yes, increase distance )
  THEN ;

: INSLINE2 ( --- )
  LINEBLANK ESC 76 EMIT WRTLINE LINES >UNDO ;

: SPLITLINE ( --- )
  INSLINE ( make room, and two copies of the line )
  LINEBYTE _CW @ + _CW @ 32 FILL ( blank the new line )
  CHARBYTE ( source for move )
  LINEBYTE _CW @ + ( destination to move )
  _CW @ _IW @ + 1 + _X @ - ( number of chars to move )
  CMOVE>
  CHARBYTE ( start of blank )
  _CW @ _IW @ + 1 + _X @ - ( number to blank )
  32 FILL
  _BLSTART @ LINEBYTE _CW @ + = IF
       _CW @ _BLSTART -!
  THEN
  TXTLEFT ESC 76 EMIT WRTLINE
  CURSORDOWN WRTLINE LINES >UNDO ;

: ENTERKEY ( --- )
  TXTLEFT CURSORDOWN ;

: COPYBLOCK ( --- )
  _BLEND @ _BLSTART @ OR IF ( is there a selected block? )
    _BLEND @ 1 + _BLSTART @ - DUP _BLKLEN ! ( find length )
    _BUFLEN @ < IF  ( will the block fit in the copy buffer? )
         _BLSTART @ _BLKBUF @ _BLKLEN @ CMOVE
    ELSE BEEP
    THEN
  ELSE BEEP
  THEN ;

: CUTBLOCK ( --- )
  _BLEND @ _BLSTART @ OR IF ( is there a selected block? )
    _BLEND @ 1 + _BLSTART @ - DUP _BLKLEN ! ( find length )
    _BUFLEN @ < IF  ( will the block fit in the copy buffer? )
         _BLSTART @ _BLKBUF @ _BLKLEN @ CMOVE
         _BLEND @ 1 + ( start of move down )
         _BLSTART @ ( end of move down )
         _TOTAL @ _BLEND @ 1 + - ( number of characters )
         CMOVE
         _BLKLEN @ _TOTAL -! ( adjust for missing block )
         _OLDMARK @ _BLSTART @ > IF
              _BLSTART @ _OLDMARK ! BLOCKNIL
         ELSE BLOCKNIL
         THEN
    ELSE BEEP
    THEN
  ELSE BEEP
  THEN ;

: PASTEBLOCK ( --- )
  _BLKLEN @ 0 > IF ( is there something in the buffer? )
     ORG _TOTAL @ - _BLKLEN @ > IF ( is there room to paste? )
         LINEBYTE  ( start of text move up )
         LINEBYTE _BLKLEN @ + ( where text moves up to )
         _TOTAL @ LINEBYTE - ( amount of text to move )
         CMOVE> ( move the text area to make room for block )
         _BLKLEN @ _TOTAL +!
         _BLKBUF @ LINEBYTE _BLKLEN @ CMOVE
         LINEBYTE _BLKLEN @ + 1 - _BLEND !
         BLOCKSTART
     ELSE BEEP
     THEN
  ELSE BEEP
  THEN ;

: DECIDE ( keypress --- ) ( _mark )
  C-OFF
  BEGCASE
       CASE CURSUP   OF CURSORUP ;;
       CASE CURSLFT  OF CURSORLEFT ;;
       CASE CURSRGT  OF CURSORRIGHT ;;
       CASE CURSDWN  OF CURSORDOWN ;;
       CASE WSUP     OF CURSORUP ;;
       CASE WSDN     OF CURSORDOWN ;;
       CASE WSLT     OF CURSORLEFT ;;
       CASE WSRT     OF CURSORRIGHT ;;
       CASE PAGDWN   OF PAGEDOWN ;;
       CASE PAGUP    OF PAGEUP ;;
       CASE TXTRGT   OF TXTRIGHT ;;
       CASE TXTLFT   OF TXTLEFT ;;
       CASE BAKSPC   OF BACKSPACE ;;
       CASE BLST     OF BLOCKSTART ;;
       CASE BLED     OF BLOCKEND ;;
       CASE BLNIL    OF BLOCKNIL ;;
       CASE REPFLG   OF REPFLAG ;;
       CASE TXTSTART OF TEXTSTART ;;
       CASE TXTEND   OF TEXTEND ;;
       CASE HELP     OF SHOWGUK ;;
       CASE UNDO     OF UNDOIT ;;
       CASE DELK     OF DELETE ;;
       CASE WSDELK   OF DELETE ;;
       CASE TAB      OF TABB ;;
       CASE CLR      OF REDRAW ;;
       CASE DELN     OF DELLINE ;;
       CASE INSLN    OF INSLINE INSLINE2 ;;
       CASE NRKEY    OF ENTERKEY ;;
       CASE SPLIT    OF SPLITLINE ;;
       CASE COPY     OF COPYBLOCK ;;
       CASE CUT      OF CUTBLOCK ;;
       CASE PASTE    OF PASTEBLOCK ;;
       ELSECASE      255 AND REP ;;
  ENDCASE CURSORBOUND POS C-ON ;

VARIABLE _OLDX  VARIABLE _OLDY  VARIABLE _CNT

: PLAYMOUSE _CNT 0!

  BEGIN
      MOUSEXY 60SYNCH _MBUFF UNSPRITE
      OVER OVER _MOUSE _MBUFF SPRITE
      MOUSEXY ROT = >R = R> + 2 =
       IF 1 _CNT +! ELSE _CNT 0! THEN
      _CNT @ 50 =
      ?KEY BUTTONS OR OR OR
  UNTIL    _MBUFF UNSPRITE ;

( ************************* )
( * The main editor loop. * )
( ************************* )

: ED ( --- )
  SP!
  0 _IW !    ( set column and indent )
  1 _REP !            ( set replace mode      )
  HERE 200 + _BLKBUF ! ( set address of block buffer )
  SCREENBASE HERE - 300 - _BUFLEN ! ( set max len for cutting )
  CURSORBOUND  _IW @ 1+ _X ! ( set cursor position )
  GETREZ 2 < ( is the res less than highres? )
  IF MEDRES THEN ( if so, put it in medres )
  DECIMAL C-ON UNWRAP
  CON: >OUT      ( send output to console only )

  _MARK @ BUFFER < _TOTAL @ ORG > OR ( test if initialized )
  IF NEW THEN ( if not, new it )

  _MARK @ 25 _CW @ * - _MARK ! BOUNDS ( find current page )
  LIST POS ( draw current page )
  >UNDO

  TOSMOUSE
  BEGIN
       MOUSEXY _OLDY @ <> >R _OLDX @ <> R> OR IF
         C-OFF PLAYMOUSE C-ON MOUSEXY _OLDY ! _OLDX ! THEN

       BUTTONS IF POSNCURS >UNDO THEN
               IF  SHOWGUK >UNDO THEN
       ?KEY IF
       KEY2 DUP DECIDE 27 = ( act on keys until esc pressed )
       ELSE 0 THEN
  UNTIL 0 24 GOTOXY CR WRAP .S ; ( exit with cursor at bottom )

: VALUES ( --- ) CR
  ." BUFFER   = " BUFFER . CR
  ." ORG      = " ORG . CR CR
  ." _BLSTART = " _BLSTART @ . CR
  ." _BLEND   = " _BLEND @ . CR CR
  ." _BLKBUF  = " _BLKBUF @ . CR
  ." _BLKLEN  = " _BLKLEN @ . CR CR
  ." _BUFLEN  = " _BUFLEN @ . CR ;

.(      Compilation successful! ) QUIT

