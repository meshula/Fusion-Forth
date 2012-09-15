
: $= ( ADDR1 ADDR2 N --- F )
   1 SWAP          ( initialize the flag to true )
   0 DO            ( check this many characters  )
      >R           ( hide the flag               )
      2DUP         ( copy the addresses          )
      C@ SWAP C@ = ( compare the characters at addr1, addr2 )
      R> AND >R    ( update the flag     )
      1+ SWAP 1+   ( point to next characters )
      R>
   LOOP ;

CREATE TEST1 ,$" HELLO1"
CREATE TEST2 ,$" HELLO2"

QUIT

