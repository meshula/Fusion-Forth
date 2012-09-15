
( ********************************************************* )
( *   FUSION Forth kernal extension:   SAVEFORTH          * )
( *                                                       * )
( *-------------------------------------------------------* )
( * software written by Don Palmer and Nick Porcino       * )
( *   copyright (c>1986 by FusionCorp                     * )
( *-------------------------------------------------------* )
( * FILE:SAVEFORTH.4TH                                    * )
( ********************************************************* )

: SEAL ( --- )
 LATEST BEGIN
    DUP COUNT 31 AND
      0 FILL ( kill a header )
    PFA 8 - @ ORG + DUP ORG =  ( point to next header  )
 UNTIL  DROP
;

HEX
: SAVEFORTH
  GET-WORD IF
    ORG 1C - 1C 0 FILL      ( blank out the file header )
    601A0000                ( GEMDOS magic longword )
    ORG 1C - !              ( get address for start of image )
    HERE 20 + ORG -         ( calculate length of file )
    ORG 1A - !              ( store in file )

    LATEST ORG - CURRENT @ !
    NEWFILE                 ( open file, get handle )
    ?DERROR DUP 0> IF       ( no errors, go on to the next bit )
      HERE 100 0 FILL       ( foil GEMDOS's relocater )
      ORG 1C -              ( get starting address )
      HERE 100 + ORG -      ( calc number of bytes to write )
      HERE ORG - DP !       ( set up for powerup relocation )
      WRITE ?DERROR DROP    ( write the image, then close it )
      HERE ORG + DP !       ( fix DP )
      CLOSE ?DERROR DROP
     ELSE DROP THEN
     LATEST ORG + CURRENT @ ! ( fix pointers )
  ELSE ."  Something is wrong." THEN ;

DECIMAL

: TURNKEY ( string --- )
      SEAL
      SAVEFORTH 0 1 GEMDOS ( terminate ) ;

: SETFENCE HERE FENCE A!
     LATEST _FENCEDEF A! ;  SETFENCE


QUIT

