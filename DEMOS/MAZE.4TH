
CREATE _MAZE1 2048 ALLOT
CREATE _MAZE2 2048 ALLOT
CREATE _MAZE3 2048 ALLOT
CREATE _M-STACK 2048 ALLOT
CREATE _M-STACK2 2048 ALLOT

VARIABLE _STACK
VARIABLE _STACK2

(  +0 FLAG:
     0=EMPTY
     1=PARENT
     2=CHILD
   +2 WHO TAGGED ME )

VARIABLE _WIN   VARIABLE _LOSE
VARIABLE _CELLS
VARIABLE _SOURCE  VARIABLE _DEST

0 CONSTANT #LOSE   1 CONSTANT #WIN
32 CONSTANT #SIZE 31 CONSTANT #SIZE-1

: PUSH ( N --- )  ( post increment )
    _STACK @ _M-STACK + ! 4 _STACK +! ;

: POP ( --- N )   ( pre decrement )
    -4 _STACK +! _STACK @ _M-STACK + @ ;

: PUSH2 ( N --- )
    _STACK2 @ _M-STACK2 + ! 4 _STACK2 +! ;
: POP2 ( --- N )
    -4 _STACK2 +! _STACK2 @ _M-STACK2 + @ ;

( ------------------------------------------------------------------- )

: NEW-PARENTS ( copy children from child array to main array )

    _M-STACK2 _M-STACK _STACK2 @ CMOVE ( copy stack2>stack1 )
    _STACK2 @ _STACK !  ( these are the points to iterate next )

         BEGIN
         _STACK2 @ WHILE
              POP2
              4* DUP _MAZE2 + DUP @ DUP IF ( calc source, get value )
                     ROT _MAZE1 + !        ( calc dest, store value )
                     0!                    ( erase cell )
              ELSE 3DROP THEN
        REPEAT ;

( ------------------------------------------------------------------- )

VARIABLE _TEMP   VARIABLE _TEMP2

: SHOW-CELL
    1 TEXTCOLOR DUP #SIZE-1 AND SWAP 4/ 4/ 2/ GOTOXY ." *" ;

: SHOW-PATH
    _DEST @ _TEMP2 !
    BEGIN
       _TEMP2 @ 4* _MAZE1 + 2+ W@
       DUP _SOURCE @ = IF DROP 1
       ELSE DUP _TEMP2 ! SHOW-CELL 0 THEN
       ?KEY OR
    UNTIL ;

: SET-CHILD ( N --- )
      DUP 4* _MAZE2 + DUP 2 SWAP W!  ( save flag )
      2+ _TEMP @ SWAP W!  ( save who called me vector )

      DUP PUSH2     ( save child number on maze stack )
      _DEST @ = IF
            BEEP #WIN _WIN !  ( if n = dest then win. )
      THEN ;

: TEST-SPOT ( N --- )

    DUP -1 > OVER _CELLS @ < AND IF ( it is on the board )
         DUP 4* _MAZE1 + @ IF ( is anybody home? )
             DROP 0  ( YES )
         ELSE
              1 ( NO, this can be a child. )
         THEN
    ELSE DROP 0 THEN

    IF SET-CHILD THEN ;

: UP
     _TEMP @ #SIZE - TEST-SPOT ; ( test up direction )

: RIGHT
     _TEMP @ 1+ DUP #SIZE-1 AND 0= NOT IF
         TEST-SPOT ELSE DROP THEN ; ( test right )

: DOWN
  _TEMP @ #SIZE + TEST-SPOT ; ( test down )

: LEFT
    _TEMP @ 1- DUP #SIZE-1 AND #SIZE-1 = NOT IF ( test left )
             TEST-SPOT
    ELSE DROP THEN ;

: CRUNCH
    1 _LOSE !
    BEGIN
    _STACK @ WHILE
        POP DUP _TEMP !  ( store cell we're testing )
        4* _MAZE1 + W@ 2 = IF
             ( is it child node? IF Yes, make it a parent )
             UP RIGHT DOWN LEFT
             1 _TEMP @ 4* _MAZE1 + W! ( make it a parent cell )
             0 _LOSE !
        THEN
        _WIN @ IF _STACK 0! THEN
    REPEAT
    NEW-PARENTS ;

: SHOW-SD
    9 TEXTCOLOR
    _SOURCE @ DUP #SIZE-1 AND SWAP 4/ 4/ 2/ ( 32/ ) GOTOXY ." S"
    _DEST   @ DUP #SIZE-1 AND SWAP 4/ 4/ 2/ GOTOXY ." D" ;

: PRINT-MAZE 0 0 GOTOXY
    16 0 DO
         #SIZE 0 DO
              I J 4* 4* 2* ( 32 * ) + 4* _MAZE1 + W@
              BEGCASE
                   CASE 0 OF SPACE ;;
                   CASE 1 OF 3 TEXTCOLOR ." ." ;;
                   CASE 2 OF 5 TEXTCOLOR ." ?" ;;
                   ELSECASE  15 TEXTCOLOR ." +" ;;
              ENDCASE
         LOOP CR
    LOOP
    SHOW-SD
    _WIN @ IF SHOW-PATH THEN ;

: SOLVE-MAZE
    C-OFF
    BEGIN
         0 17 GOTOXY
         CRUNCH
         CR
         PRINT-MAZE
         _WIN @ _LOSE @ OR
         ?KEY OR
    UNTIL
    0 21 GOTOXY C-ON ;

( --------------------------------------------------------------- )

VARIABLE _TX   VARIABLE _TY

: RESET  100 100 MOUSEXY! ;

: GET-MSE
         C-ON
         RESET
         BEGIN
              MOUSEXY
              DUP 105 > IF 1 _TY +!  _TY @ 15 AND _TY ! RESET THEN
                   95 < IF 1 _TY -!  _TY @ 15 AND ABS _TY ! RESET THEN
              DUP 105 > IF 1 _TX +!  _TX @ 31 AND _TX ! RESET THEN
                   95 < IF 1 _TX -!  _TX @ 31 AND ABS _TX ! RESET THEN
              _TX @ _TY @ GOTOXY
         BUTTONS OR UNTIL _TX @ _TY @ WAITBUTTON C-OFF ;

: GET-SOURCE
         0 24 GOTOXY ." Place start"
         GET-MSE 32 * +
         _SOURCE !
         2 _MAZE1 _SOURCE @ 4* + W! SHOW-SD
         _SOURCE @ PUSH ;

: GET-END
         0 24 GOTOXY ." Place end  "
         GET-MSE 32 * +
         _DEST ! SHOW-SD ;

: GET-WALLS
         0 24 GOTOXY ." Place walls"
         BEGIN
         ?KEY NOT WHILE
              GET-MSE 32 * + 4* _MAZE3 + DUP W@ 0= 3 *
              SWAP OVER SWAP W!
              _TX @ _TY @ GOTOXY IF ." +" ELSE SPACE THEN
         REPEAT KEY DROP
         _MAZE3 _MAZE1 2048 CMOVE ;

: MAZE   LOWRES
         _STACK 0!
         #LOSE _WIN !
         512 _CELLS !
         _SOURCE 0!  _DEST 0!  _TX 0!  _TY 0!
         _MAZE1 2048 0 FILL
         _MAZE2 2048 0 FILL
         _MAZE3 2048 0 FILL
         15 SETCOLOR
         256 0 256 128 YADJ LINE
         0 128 YADJ 256 128 YADJ LINE
         GET-WALLS
         GET-SOURCE
         GET-END
         SOLVE-MAZE ;

: AGAIN  LOWRES
         _STACK 0!
         #LOSE _WIN !
         _MAZE3 _MAZE1 2048 CMOVE
         PRINT-MAZE
         15 SETCOLOR
         256 0 256 128 YADJ LINE
         0 128 YADJ 256 128 YADJ LINE
         GET-WALLS
         GET-SOURCE
         GET-END
         SOLVE-MAZE ;

: FAST   LOWRES
         _STACK 0!
         #LOSE _WIN !
         _MAZE3 _MAZE1 2048 CMOVE
         PRINT-MAZE
         15 SETCOLOR
         256 0 256 128 YADJ LINE
         0 128 YADJ 256 128 YADJ LINE
         GET-SOURCE
         GET-END
         BEGIN
              CRUNCH
              _WIN @ _LOSE @ OR
              ?KEY OR
         UNTIL
         PRINT-MAZE
         0 21 GOTOXY
         C-ON ;

EXIT

