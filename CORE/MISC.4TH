
DECIMAL

( ********************************************************** )
( *  FORTH kernal extensions                               * )
( *     including:  (, .", .(, .S, VARIABLE, FORGET        * )
( *                  TEE, and the rest...                  * )
( *        "HERE ON GILLIGAN'S ISLE!"                      * )
( *                                                        * )
( *  software by Nick Porcino and Don Palmer               * )
( *--------------------------------------------------------* )
( *  FILENAME: MISC.4TH                                    * )
( ********************************************************** )

VARIABLE _FENCEDEF

: AT GOTOXY ;    : CONVERT <NUMBER> ;

: .( CR 41 WORD HERE COUNT TYPE ; IMMEDIATE
:  { 125 WORD ; IMMEDIATE ( "super comment" delimited by "}" )

: ,$" 34 WORD HERE DUP COUNT ALLOT DROP
      DUP 1+ SWAP DUP C@ CMOVE ;

.( * KERNAL extensions                                     * )

: -ROT ROT ROT ;

: >FP ( n1 n2 --- fp1 )
   65536 * BASE @ DUP * DUP * / SWAP 65536 * + ;

: FP> ( fp1 --- n1 n2 )
   DUP 0< IF NEGATE THEN
   DUP 65536/ DUP -ROT 65536* -
   BASE @ DUP * DUP * * 65536/ ;

: .FP ( fp1 --- )
     DUP 0< IF ." -" THEN FP> SWAP . ." ." . ;

: .S  DEPTH IF        ( non destructively prints the contents )
        DEPTH 0 DO    ( of the stack.                         )
          CR I PICK .
        LOOP
      ELSE
       ."  Stack Empty" CR
      THEN ;

: DOES> R> LATEST PFA A! SMUDGE [COMPILE] [ ;

( *-------------------------------------------------------* )

( EAKER CASE STATEMENT FROM CEE 9/80 FORTH DIMENSIONS II/3 P 37)

: ?PAIRS = DROP ;

: CASE2 ?COMP CSP @ SP@ CSP ! 4 ; IMMEDIATE
: OF2 4 ?PAIRS
    COMPILE OVER COMPILE = COMPILE 0BRANCH HERE 0 ,
    COMPILE DROP 5 ; IMMEDIATE
: ENDOF2 COMPILE BRANCH HERE 0 , SWAP 2
    [COMPILE] THEN 4 ; IMMEDIATE
: ENDCASE2 4 ?PAIRS
     COMPILE DROP BEGIN SP@ CSP @ = 0= WHILE
     2 [COMPILE] THEN REPEAT CSP ! ; IMMEDIATE

( *-------- DICTIONARY WORDS: ----------------------------* )

: FORGET [COMPILE] ' DUP
    FENCE @ ORG + > IF
       DUP NFA DP ! 4 -  @ ORG + CURRENT @ !
    ELSE 1 7 ?ERROR THEN ;

: EMPTY FENCE A@ DP !
    _FENCEDEF A@  CURRENT @  ! ;

: LFA ( PFA --- LFA ) 8 - ;
: >LINK LFA ;  : >BODY PFA ;  : NAME> NFA ;

: BINARY 2 BASE ! ;  : OCTAL 8 BASE ! ;

( *-------- I/O words: -----------------------------------* )

-1 CONSTANT NULL:
 0 CONSTANT LST:    1 CONSTANT AUX:    2 CONSTANT CON:
 3 CONSTANT MIDI:   4 CONSTANT IKBD:   5 CONSTANT SCREEN:

: TEE ( n1 n2 --- ) _OUT1 ! _OUT2 ! ;
: >OUT ( n --- ) _OUT1 !   NULL: _OUT2 ! ;
: AS-INPUT _IN ! ;

: C-ON 27 EMIT ." e" ;  : C-OFF 27 EMIT ." f" ;
: RVS-ON 27 EMIT ." p" ;  : RVS-OFF 27 EMIT ." q" ;

: TEXTCOLOR ( n --- ) GETREZ 2 <> IF
       27 EMIT ." b" EMIT
       ELSE DROP THEN ;

: BACKCOLOR ( n --- ) GETREZ 2 <> IF
       27 EMIT ." c" EMIT
       ELSE DROP THEN ;

: ERASE ( addr n --- ) 0 FILL ;

: FLUSH ( -- ) 15 6 DO I CLOSE DROP LOOP ;

: LOGOFF
     _SYSFONT @ LOAD-FONT
     STARTREZ @ GETREZ <>
       IF STARTREZ @ L>W -1 -1 5 L>W 6 XBIOS DROP THEN
     GEMMOUSE SHOWMOUSE
     27 EMIT 102 EMIT

     CON: >OUT FLUSH
     CR ." Watch your back, laser-bait!"

     MEDCOLORS SETCOLORS
     0 L>W 1 GEMDOS ;

: C, ( n --- ) HERE C! 1 DP +! ;

: RECURSE LATEST PFA CFA A, ; IMMEDIATE

: LEAVE R> R> DROP DUP >R >R ;

: TEXT ( addr c --- ) PAD 72 32 FILL WORD COUNT PAD SWAP
                        CMOVE> ;

1 CONSTANT TRUE        0 CONSTANT FALSE

( * bit blt extensions:                                    * )
( * use: VARIABLE <name> 36 ALLOT                          * )
( *      <value> <name> <parameter>                        * )
( * then: <name> MEDBLT   <name> LOWBLT   <name> HIBLT     * )

: SX        ! ;  : SY    4 + ! ;  : SH    8 + ! ;  : SW 12 + ! ;
: DX   16 + ! ;  : DY   20 + ! ;  : MODE 24 + ! ;
: SADD 28 + ! ;  : DADD 32 + ! ;

 ( ********************************************************* )
.( * GEMDOS extensions                                     * )
 ( ********************************************************* )

VARIABLE _DTA 64 ALLOT ( disk transfer area )

: DFREE ( --- bytes )
  0 L>W _DTA 54 L>W 4 GEMDOS DROP
  _DTA @ _DTA 8 + @ * _DTA 12 + @ * ;

: 64ENTER
  GET-WORD IF
    OPEN ?DERROR DUP 0> IF
      BUFFER ORG BUFFER - READ
      ?DERROR >R CLOSE ?DERROR DROP
      R> DUP 0> IF
        BUFFER + _TOTAL ! BUFFER _MARK !
        _X 0!  _Y 0!
        64 _CW !  5 _IW !
        _BLEND 0!  _BLSTART 0!  _BLKLEN 0!
      ELSE ."  ** Error during read" CR QUIT THEN
    ELSE ."  ** Couldn't open file" CR QUIT THEN
  ELSE 2DROP ."  Syntax Error" ABORT
  THEN ;

: 64SAVE ( --- )
  GET-WORD IF
     NEWFILE ?DERROR ( create file and get handle )
     BUFFER _TOTAL @ BUFFER - WRITE ?DERROR DROP
     CLOSE ?DERROR DROP ( CLOSE FILE )
    ELSE ."  Syntax Error" ABORT
  THEN ;

HEX

: GETDATE ( --- date month year ) 2A L>W 1 GEMDOS
  DUP 1F AND SWAP     ( date  )
  DUP 20 / F AND SWAP ( month )
  200 / 7BC +         ( year  ) ;

: SETDATE ( date month year --- )
   7BC - 200 *    (  year )
   SWAP 20 * +    ( month )
   SWAP 1F AND +  (  date )
   L>W 2B L>W 2 GEMDOS DROP ;

: GETTIME ( --- hours minutes seconds ) 2C L>W 1 GEMDOS
   DUP 800 / 1F AND DUP F > IF 1- THEN SWAP ( hours   )
   DUP 20 / 3F AND SWAP  ( minutes )
   1F AND 2*             ( seconds ) ;

: SETTIME ( hours minutes seconds --- )
   2/ 1F AND SWAP       ( seconds )
   3F AND 20 * + SWAP   ( minutes )
   800 * +              ( hours   )
   L>W 2D L>W 2 GEMDOS DROP ;

: .2 ( n --- ) DUP A < IF ." 0" THEN . ;

: .TIME   ( --- ) BASE @ >R DECIMAL
    GETTIME ROT . ." :" SWAP .2 ." :" .2
    R> BASE ! ;

DECIMAL

CREATE _MONTHS ,$" JanFebMarAprMayJunJulAugSepOctNovDec"

: .DATE ( --- ) BASE @ >R DECIMAL
    GETDATE ROT . SPACE
    SWAP 1- 3 * _MONTHS + 3 TYPE SPACE
    .
    R> BASE ! ;

( ********************************************************** )
( * more graphics stuff:                                   * )
( ********************************************************** )

: PERROR ."  Couldn't open picture file." ;

( load a DEGAS format picture, and set the color registers if
  flag is true. )

: DEGASLOAD ( string addr flag --- )
    >R >R OPEN ?DERROR  ( open the picture )
       DUP 0> IF
          R@ 34 READ DROP ( get the color info )
          R> R>       ( fetch the flag, set colors if req'd )
          IF DUP 2+ SETCOLORS THEN
          32000 READ ?DERROR
          0< IF PERROR THEN
          CLOSE DROP DROP
       ELSE DROP R> R> PERROR ABORT THEN ;

( load a NEOCHROME format picture, and set the color registers
  if flag is true. )

: NEOLOAD ( string addr flag --- )
    >R >R OPEN ?DERROR  ( open the picture )
       DUP 0> IF
          R@ 128 READ DROP ( get the color info )
          R> R>     ( fetch the flag, and set colors if req'd )
          IF DUP 4+ SETCOLORS THEN
          32000 READ ?DERROR
          0< IF PERROR THEN
          CLOSE DROP DROP ( the 2nd DROP drops a spurious lw )
       ELSE DROP R> R> PERROR ABORT THEN ;

 ( ********************************************************* )
.( *  operating system extensions                          * )
 ( * including: DIR CD DEL A: B: C: D:                     * )
 ( ********************************************************* )

CREATE DEV$
,$" PRT:AUX:CON:MIDIIKBDSCRN"

: .DEV ( device --- )
     DUP 5 > IF
       ." File: handle " .
     ELSE
       DUP 0> IF
          4* DEV$ + 4 TYPE
       ELSE
          DROP ." NULL:"
       THEN
     THEN ;

: STATUS
     CR ." Fusion Forth v1.0" CR
     CR  .DATE 2 SPACES .TIME CR CR
     ." Input device: " _IN @ .DEV CR
     ." Output device 1: " _OUT1 @ .DEV CR
     ." Output device 2: " _OUT2 @ .DEV CR CR

     ."         Address  Length"             CR
     ." BUFFER " BUFFER 8 .R BUFFSIZE @ 8 .R CR
     ." FORTH  " ORG    8 .R HERE ORG - 8 .R CR
     ." FREE   " HERE   8 .R SCREENBASE HERE - 8 .R CR ;

: COLD
   COLDSTUFF TOSMOUSE

   ( initialize the font pointer if it is undefined. )
   INIT-FONT

   MEDRES C-OFF
   ( _FONT @ IF _FONT A@ ELSE _SYSFONT @ THEN LOAD-FONT )

   BUFFER 128 - C$ 127 CMOVE ( copy the TTP command line to C$)

    GETREZ DUP 1 = IF  ( check rez, and save it for later )
      3 SETCOLOR
      0 0 639 50 FRAME
      ELSE 0 0 639 100 FRAME
    THEN

    2 1 GOTOXY ." Fusion FORTH 1.0"
    2 2 GOTOXY ."  copyright 1987 by Nick Porcino and Don Palmer"
    2 4 GOTOXY ."  all rights reserved."

  HOME 1 = IF   ( check rez for monochrome or color )

     600 17 MOVETO   ELSE   600 34 MOVETO   THEN
        ( plot a squiggly                          )
     180 0 DO 5 FORWARD I 10 * 1 + RIGHT LOOP

     ( turn on cursor and allow output to wrap: )
     0 7 GOTOXY 27 EMIT ." e" 27 EMIT ." v"

     78 DUP _CW !  C/L !  _IW 0!

  DECIMAL STATUS
 ABORT ;

' COLD STARTWORD A! ( set so boot up invokes COLD )

: WORDS CR LATEST 0 >R
   BEGIN
     DUP COUNT 31 AND TYPE SPACE
     PFA LFA @ ORG + R> 1+ >R
     DUP ORG = ?KEY
   OR  UNTIL DROP

   ?KEY IF KEY DROP THEN
   CR R> . ."  WORDS." CR ;

HEX
: MDUMP ( addr n --- )
  BASE @ >R HEX
   0 DO CR DUP I + DUP 6 .R
   2 SPACES DUP
   8 0 DO DUP I + C@ 3 .R LOOP
   DROP SPACE DUP 8 +
   8 0 DO DUP I + C@ 3 .R LOOP
   DROP ."  |"
   10 0 DO DUP I + C@ DUP 20 < OVER 7F > OR
     IF DROP 2E THEN EMIT
   LOOP DROP
 10 +LOOP
 DROP CR R> BASE ! ;
DECIMAL

: DUMP DUP 128 MDUMP 128 + ;

: .DFREE  ."  <" DFREE . ."  BYTES FREE>" CR ;

: DIRPRN ( print out a line of file info )
  ."  | "
  _DTA 21 + C@ 16 AND IF 175 ELSE 32 THEN EMIT
  SPACE _DTA 30 + 13 TYPE ( file name )
  _DTA 26 + @ DUP 0 > IF 7 .R    ( file size )
  ELSE ."     ---" DROP THEN ."  |" CR ;

: BLNM ( blank the name holder )
  _DTA 30 + 13 BL FILL ;

: CTYPE ( ADDR --- ) ( prints out a 0 terminated string )
  1 - BEGIN 1 + DUP C@ DUP EMIT 0 = UNTIL DROP ;

: KEYHOLD ( pauses if key pressed )
  11 L>W 1 GEMDOS IF
       8 L>W 1 GEMDOS 255 AND 32 = IF
            8 L>W 1 GEMDOS DROP THEN THEN ;

: DIR ( --- )
  GET-WORD NOT IF 2DROP " *.*" THEN C$ SWAP CMOVE
  CR CR
  _DTA 26 L>W 3 GEMDOS DROP ( set up disk transfer address )
  ."    " 25 L>W 1 GEMDOS 65 + EMIT ." :" ( find drive )
  0 L>W _DTA 71 L>W 4 GEMDOS DROP _DTA CTYPE CR ( find path )
  ."   -----------------------" CR
  BLNM 17 L>W C$ 78 L>W 4 GEMDOS ( first search )
       NOT IF KEYHOLD DIRPRN   THEN ( yes we have a file )
       BEGIN BLNM 79 L>W 1 GEMDOS DUP ( next searches )
            NOT IF KEYHOLD DIRPRN THEN
       UNTIL  ( out of files )
  ."   -----------------------" CR ;

: CD   ( change the active directory
          format:   CD pathname       )

  GET-WORD NOT IF 2DROP " .." THEN
     $>C$ 59 L>W 3 GEMDOS ?DERROR DROP ;

: DRVMAP ( --- n ) 10 L>W 1 BIOS ;
: SETDRIVE ( n1 n2 --- )
     DRVMAP AND IF
       L>W 14 L>W 2 GEMDOS DROP
     ELSE ."  Drive is not available." THEN ;

: A: 0 1 SETDRIVE ;  : B: 1 2 SETDRIVE ;   : C: 2 4 SETDRIVE ;
: D: 3 8 SETDRIVE ;

: DEL   ( delete a file
           format:   DEL filename    )

  GET-WORD IF
     $>C$ 65 L>W 3 GEMDOS ?DERROR DROP
  ELSE 2DROP ."  ** Filename required! **"
  THEN ;

QUIT

