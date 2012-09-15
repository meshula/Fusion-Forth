
.( St. Feder )

DECIMAL

CREATE PBUFF ( pointer buffer, room for 2000 paragraphs. )
   8000 ALLOT

CREATE TextBuff
   8000 ALLOT ( enough room for a two page paragraph )

CREATE _P1
 ,$"      Puff the magic dragon, lived by the sea, "
 ,$" and frolicked in the autumn "
 ,$" mist in a land called Honnolee.  Little Jackie Paper, loved that "
 ,$" rascal Puff, and brought him bits of sealing wax, and "
 ,$" other fancy stuff." 10 C,
 ,$" This is a test" 10 C,
 ,$" This is the second test line" 10 C,
 ,$" This is the third test line." 13 C,

CREATE _P2
 ,$"      In the town where I was born lived a man who sailed "
 ,$" to sea, and he told me of his life in the land of submarines.  "
 ,$" So I sailed up to the sun, until I found the sea of green, and "
 ,$" there I lived beneath the waves, in a yellow submarine.  " 13 C,

24 CONSTANT #PageBot   ( Bottom of the page )
VARIABLE _YPOS         ( Current cursor y position )

VARIABLE _PPtr      ( Pointer to beginning of Paragraph )
VARIABLE _PLen      ( Paragraph Length )
VARIABLE _POffSet   ( Offset from top of page into paragraph )

VARIABLE _Tptr         ( Text pointer )
VARIABLE _Term         ( Terminate flag )
VARIABLE _Xctr         ( X counter )

: CR? ( c --- f c ) ( returns t if c is a CR char )
    DUP 13 = ;

( WrLine writes out a single line, given a starting address.               )
( It will print until 80 characters have been output, or an EOL is reached )
( The address returned is the address of the next char of the block.       )
( Note that a paragraph will always be terminated by a CR or a LF.         )

VARIABLE _BlFlag ( SPACE flag )
VARIABLE _BlX    ( the X where the SPACE happenned )

( EndLine takes addr1.  If addr1 contains a space, that space is changed )
(   into a linefeed, and that's all that happens.                        )
(   Otherwise, is there a space on the line?                             )
(   If no, nothing happens.  If there IS a space on the line, EndLine    )
(   will put a LF where _BlFlag points, and erase the chars on the       )
(   after that point.                                                    )

: EndLine ( addr1 --- addr2 )
             TRUE _Term !      ( done with this line. )
             DUP C@ BL = IF    ( is next char a space? )
                DUP 10 SWAP C! ( yes, store a LF there instead )
             ELSE
                _BlFlag @ IF             ( is there a space on this line? )
                   10 _BlFlag @ C!       ( store a LF at the last space )
                   DROP                  ( throw away addr1 )
                   _BlFlag @ 1+          ( and use BlFlag instead )
                   _BlX @ _YPOS @ GOTOXY
                   ESC 75 EMIT           ( clear to end of line )
                THEN ( IF space on line. )
             THEN    ( IF space ) ;

: WrLine ( FirstCharToPrint --- NextCharToPrint )
    _Xctr 0!
    _BlFlag 0!
    FALSE _Term !

    BEGIN                ( gobble space characters at beginning of line )
       DUP C@                    ( space? )
       CR? NOT IF
          DUP BL = SWAP 10 = OR NOT IF
             TRUE _Term !           ( if not space, then exit this loop. )
          ELSE
             1+                     ( if space, then test next )
          THEN
       ELSE
          DROP TRUE _Term !
       THEN
    _Term @ UNTIL

    FALSE _Term !

    BEGIN
       DUP 1+ SWAP       ( get char, and leave next addr under it )
       C@
       DUP BL = IF
          OVER 1- _BlFlag ! ( if it's a space, store the addr )
          _Xctr @ _BlX !    ( and the x coordinate )
       THEN
       CR? IF            ( end of paragraph? )
          DROP
          TRUE _Term !
       ELSE
          DUP 10 = IF       ( is it a line feed? )
             DROP DUP 1-    ( yes, change it into a space )
             DUP _BlFlag !  ( and store the addr of the space )
             BL SWAP C!
             SPACE          ( print a space )
             _Xctr @ _BlX ! ( store the x coordinate of the space )
          ELSE
             EMIT
          THEN
       THEN

       1 _Xctr +!              ( inc x posn )
       _Xctr @ 80 >= IF        ( last x ? )
          _Term @ NOT IF       ( last char printed a CR ? )
             EndLine           ( not a CR, do something with it )
          THEN       ( IF CR )
       THEN          ( IF lastX )
    _Term @ UNTIL ;

: ShowPar ( addr --- Shows the paragraph starting at addr )
  _Tptr !
  _PLen @ IF                         ( Non-zero paragraph length? )

    BEGIN                            ( Print out max of twenty five lines )
       0 _YPOS @ GOTOXY
       _Tptr @ WrLine _Tptr !
       1 _YPOS +!
    _YPOS @ #PageBot >=              ( Repeat until 25 lines, or until EOP )
    _Tptr @ 1- C@ 13 = OR UNTIL

  THEN ;

: WrPage ( addr --- Shows the page starting with pointer at addr )
    BEGIN
       DUP
       @ ShowPar          ( show paragraph pointed to )
       4+                 ( inc pointer )
    DUP @ 0=              ( repeat until no more links )
    _YPOS @ #PageBot >=   ( or until end of page )
    OR UNTIL DROP ;

: Init
   _YPOS 0!
   1 _PLen !
   _POffSet 0!
   TextBuff _PPtr !
   _P1 PBUFF    !       ( set up a phoney paragraph list )
   _P2 PBUFF 4+ !
   _P1 PBUFF 8 + !
   _P2 PBUFF 12 + !
   _P1 PBUFF 16 + !
   _P2 PBUFF 20 + !
   _P1 PBUFF 24 + !
   _P2 PBUFF 28 + !
   _P1 PBUFF 32 + !
   _P2 PBUFF 36 + !
   PBUFF 40 + 0! ;

: FEDER
    Init
    PAGE
    PBUFF WrPage KEY DROP ;

.( invoke: FEDER )

QUIT

