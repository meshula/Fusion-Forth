
VARIABLE _GX VARIABLE _GY
VARIABLE _GN ( the final value )

: GO-GXGY _GX @ _GY @ GOTOXY ;

: SHOW-GN C-OFF GO-GXGY  _GN @
      DUP 0=
      IF DROP SPACE SPACE GO-GXGY
      ELSE . SPACE 8 EMIT C-ON
      THEN ;

: NUMER?     48 - DUP -1 > OVER 10 < AND
             IF ( else, is it numeric? )
                 _GN @ -1 >
                 IF
                     _GN @ 10 * _GN ! _GN +!   ( yes, store it )
                 ELSE
                     _GN @ 10 * _GN ! _GN -!
                 THEN
                 SHOW-GN
             ELSE
                 DROP ( else, throw away the key )
             THEN  ;

: PROCESS ( KEY --- FLAG )
    DUP 13 =
    IF
         DROP 1 ( is key cr? yes... terminate )
    ELSE
         DUP 45 =
         IF ( else, is it "-"? )
             DROP ( throw the key away )
             _GN @ -1 * _GN ! ( yes, negate it )
             SHOW-GN
         ELSE
             DUP 8 =
             IF
                DROP _GN @ 10 / _GN ! SHOW-GN ( kill the last digit )
             ELSE
                NUMER?
             THEN
         THEN
    0
    THEN ;

: DIGITZ ( X Y --- N )
     _GY !  _GX !   GO-GXGY  _GN 0!
     BEGIN
        KEY
        PROCESS
     UNTIL ;

: TEST 0 3 DIGITZ CR ." THE ANSWER IS:" _GN @ . ;

QUIT

