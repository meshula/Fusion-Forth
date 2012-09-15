
: VAR VARIABLE ; IMMEDIATE

VAR 'FONT
VAR _PNTR
VAR _HANDLE  VAR _WIDTH  VAR _WID
VAR _CHAR    VAR _FLAG

CREATE _PFONT 5000 ALLOT

: NEW-FONT
    8 _PFONT W! ( number of lines in each character )
    _PFONT 2+ 128 8 FILL ( spacing information )
    _PFONT 130 + 2048 0 FILL ( clear out the font before hand )

    _PFONT 131 + _PNTR !

    _FONT @ IF _FONT A@ ELSE _SYSFONT @ THEN 'FONT !
    256 0 DO  ( 128 Characters in set )
         8 0 DO  ( 8 Lines in each character )
              J I 256 * + 'FONT @ + C@ ( get a line of the character )
              _PNTR @ C! 2 _PNTR +! ( store a line, inc pointer )
         LOOP
    LOOP ;

: DUMP-FONT
     HEX
     _PFONT 131 + _PNTR !
     CR
     256 0 DO
         ."  dc.b "
         8 0 DO
             J 16 * I 2* + _PNTR @ + C@
             ." 0,$"
             DUP 16 < IF ." 0" THEN
             . ." ,"
         LOOP
         ."  ; " I DUP 33 < IF . ELSE DUP . SPACE EMIT THEN CR
   (      I 20 MOD NOT IF KEY DROP THEN  )
      LOOP ;

QUIT

