
DECIMAL
.( Compiling the file selector box )   ( FSEL.4TH )

: _NameArray SCREENBASE 4000 - ;

VARIABLE _CL  VARIABLE _CF

: STUFFIT
    _DTA 30 + C@ 46 = NOT IF
         _DTA 21 + C@ 16 AND IF 7 ELSE 32 THEN
         _CL @ C! 1 _CL +!
         _DTA 30 + _CL @ 12 CMOVE
         12 _CL +!
         1 _CF @ +! THEN ;

CREATE _SEPA 42 C, 46 C, 42 C, 0 C,

: DIRPR
    _DTA 21 + C@ 16 AND IF STUFFIT THEN ;

: DIRPR2
    _DTA 21 + C@ 16 AND NOT IF STUFFIT THEN ;

: BLM _DTA 30 + 13 BL FILL ;

: GDIR ( BUFFER-LOC )
    DUP _CF ! _CL ! 4 _CL +! _CF @ 0!
    C$ SWAP CMOVE
    _DTA 26 L>W 3 GEMDOS DROP          ( set up disk transfer address )
    BLM 17 L>W _SEPA 78 L>W 4 GEMDOS                   ( first search )
    NOT IF DIRPR THEN                           ( yes, we have a file )
    BEGIN BLM 79 L>W 1 GEMDOS DUP                     ( next searches )
         NOT IF DIRPR THEN
    UNTIL                                              ( out of files )

    BLM 17 L>W C$ 78 L>W 4 GEMDOS                      ( first search )
    NOT IF DIRPR2 THEN                          ( yes, we have a file )
    BEGIN BLM 79 L>W 1 GEMDOS DUP                     ( next searches )
         NOT IF DIRPR2 THEN
    UNTIL ;                                            ( out of files )

CREATE FSEL$  3 ,  7 , 2 , 15 , 1 , ,"   " 40 ALLOT

CREATE M1$    3 ,  8 , 4 , 1 , 3 , ," Match:"
CREATE MATCH$ 6 , 14 , 4 , 1 , 3 , ,"             " 4 ALLOT
CREATE F1$    3 ,  8 , 6 , 1 , 3 , ," File: "
CREATE FILE$  6 , 14 , 6 , 1 , 3 , ,"             " 0 C, 4 ALLOT

CREATE FSEL-SCAF 7 ,
    8 C,  8 C, ( X Y )
    1 W,  0 W, ( CUR OFFSET )
   12 C, 13 C, ( HEIGHT WIDTH )
   _NameArray A,

CREATE CLOS-B 2 , 1 , 24 , 9 ,  ,"  CLOSE DIR "
CREATE DONE-B 2 , 1 , 24 , 11 , ,"    DONE    "
CREATE CANX-B 2 , 1 , 24 , 13 , ,"   CANCEL   "
CREATE SPAC-B 2 , 1 , 24 , 15 , ,"    FREE    "

CREATE FSEL-BOX
    1 , 3 , 1 , _SLASH A, 1 ,
    6 , 1 , 38 , 23 ,
   10 , FSEL$ A,
        M1$ A, MATCH$ A, ( 1/2 )
        F1$ A, FILE$ A,  ( 3/4 )
        CLOS-B A, CANX-B A, DONE-B A, ( 5/6/7 )
        FSEL-SCAF A, ( 8 )
        SPAC-B A, ( 9 )

: SET-FILE$
    FSEL-SCAF 6 + W@ ( which element is currently selected? )
    ?DUP IF ( if something is selected then find out what )
         1- 13 * _NameArray + 5 + ( offset into name array )
         FILE$ 21 + 12 CMOVE ( copy the filename )
    THEN ;

: SHOW-DFREE 24 18 GOTOXY ." Free Space:" 25 19 GOTOXY DFREE . ;

: DRAW-FSEL ( MATCH$ --- )
    _NameArray GDIR
    SET-FILE$
    FSEL-BOX DRAWTREE ( draw all the techy bits )
    1 TEXTCOLOR 3 BACKCOLOR 8 5 GOTOXY ." Path: "
    14 5 GOTOXY
    25 L>W 1 GEMDOS 65 + EMIT ." :" ( find drive )
    0 L>W _DTA 71 L>W 4 GEMDOS DROP
    _DTA CTYPE SPACE CR ( print path ) ;

: NewDrawFsel
       _NameArray FSEL-SCAF 12 + A!
       0 FSEL-SCAF 8 + W!
       0 FSEL-SCAF 6 + W! MATCH$ 21 + 12 DRAW-FSEL ;

: GET-MOUSE
    BEGIN
         60SYNCH MOUSEXY _MBUFF UNSPRITE
         _MOUSE _MBUFF SPRITE
    BUTTONS OR UNTIL
    _MBUFF UNSPRITE ;

: CL-DIR ( close one level of directory )
    " .." $>C$ 59 L>W 3 GEMDOS DROP
    NewDrawFsel ;

.( 5 )

: NEW-FILE
    FSEL-SCAF 6 + W@ ( fetch selected slot )
    _NameArray @ ( get # of occupied slots )
    <= IF
         FSEL-SCAF 6 + W@
         1- 13 * _NameArray + 4+ DUP ( calc address of entry )
         C@ 7 = IF ( file or subdirectory? )
              1+ 12 ( set up string )
              $>C$ 59 L>W 3 GEMDOS DROP ( log new directory )
              NewDrawFsel ( and show what's in it )
         ELSE DROP
              SET-FILE$ FILE$ EDIT$ DROP
         THEN
    THEN ;

VARIABLE _FCODE ( exit code: 0=cancel 1=do it yeah! )

: FS ( match$ title$ --- )
       SWAP OVER FSEL$ 21 + SWAP CMOVE ( copy the title string )
       FSEL$ 20 + C!           ( store the string's count byte )
       MATCH$ 21 + SWAP CMOVE         ( copy the search string )

       NewDrawFsel

       BEGIN
         GET-MOUSE
         FSEL-BOX GOTCLICK WAITBUTTON
             _BOX @ IF
                 _OBJ @
                 BEGCASE
                    CASE 2 ( match$   ) OF NewDrawFsel  0 ;;
                    CASE 5 ( close    ) OF CL-DIR       0 ;;
                    CASE 6 ( cancel   ) OF _FCODE 0!    1 ;;
                    CASE 7 ( done     ) OF 1 _FCODE !   1 ;;
                    CASE 8 ( scaffold ) OF NEW-FILE     0 ;;
                    CASE 9 ( free space ) OF SHOW-DFREE 0 ;;
                    ELSECASE 0 ;;
                 ENDCASE
             ELSE 0 THEN
       UNTIL ;

: FSEL ( search$ prompt$ --- filename$ flag )
      FS
      FILE$ 20 + COUNT ( get selected file name )
      _FCODE @ ;

QUIT


