
( ****************************************************** )
( *   Editor support routines                          * )
( *----------------------------------------------------* )
( * software by Nick Porcino                           * )
( * copyright (c>1986 FusionCorp all rights reserved   * )
( *----------------------------------------------------* )
( * FILE: PRINT.4TH                                    * )
( ****************************************************** )

DECIMAL

CREATE _PRINTB
  2 , 1 , 44 , 17 ,
  ,"  PRINT BLOCK "

CREATE _PRINTB2
  2 , 1 , 28 , 17 ,
  ,"  PRINT FILE "

CREATE _HDR$
  6 , 10 , 15 , 1 , 3 ,
  ," Fusion Program Editor v2.0               "
  0 ,

CREATE _PRINTBOX
  1 , 1 , 1 , _SLASH A, 1 ,
  8 , 10 , 58 , 19 ,
  3 , _PRINTB A, _PRINTB2 A, _HDR$ A,

VARIABLE _LOCAL1  VARIABLE _LOCAL2

: PRSTUFF ( --- )
    LST: >OUT
    _LOCAL2 @ _LOCAL1 @ DO
       CR CR 5 SPACES _HDR$ 20 + COUNT TYPE
       2 SPACES .DATE 2 SPACES .TIME CR CR CR
       55 0 DO
          I _CW @ * J + ( address of current line )
          DUP _CW @ + _LOCAL2 @ > IF DROP LEAVE
          ELSE _IW @ SPACES  _CW @ TYPE CR THEN
       LOOP
       12 EMIT ( do a page feed )
    55 _CW @ * +LOOP
    CON: >OUT ;

: PRFILE BUFFER _LOCAL1 !  _TOTAL @ _LOCAL2 ! PRSTUFF ;
: PRBLK _BLSTART @ IF
      _BLSTART @ _LOCAL1 ! _BLEND @ _LOCAL2 ! PRSTUFF
    THEN ;

: PRINTBOX
    _PRINTBOX DRAWTREE

    BEGIN
       MOUSEXY 60SYNCH _MBUFF UNSPRITE
                       _MOUSE _MBUFF SPRITE
       BUTTONS IF
          _MBUFF UNSPRITE
          _PRINTBOX GOTCLICK
          _BOX @ 1 = IF
             _OBJ @ BEGCASE
                CASE 0 OF PRBLK ;;
                CASE 1 OF PRFILE ;;
                ELSECASE ;;
             ENDCASE
          THEN
       THEN

    UNTIL _MBUFF UNSPRITE WAITBUTTON ;

EXIT



