
( HOPALONG  FROM DEWDNEY'S MATHEMATICAL RECREATIONS
                  SCIENTIFIC AMERICAN, SEPT. 1986 )

VARIABLE _A  VARIABLE _B  VARIABLE _C   VARIABLE _SCALE
VARIABLE _X  VARIABLE _Y
VARIABLE _COLOR

: HOP  _X 0!  _Y 0!

   BEGIN
      _X @ _SCALE @ / _Y @ _SCALE @ / 100 YADJ + SWAP 160 YADJ + SWAP PLOT
      _Y @
      _B @ _X @ * 10000 / _C @ - ABS 10000 * SQRT
      _X @ 0> IF 1 ELSE -1 THEN * -

      _A @ _X @ - _Y !

      _X !    ?KEY IF C-ON ABORT THEN
      1 _COLOR +!  _COLOR @ 100 / ?DUP IF SETCOLOR ELSE 1 SETCOLOR THEN
   0 UNTIL ;

: HOPALONG LOWRES C-OFF 1 _COLOR ! 1 SETCOLOR
       _C ! _B ! _A ! _SCALE ! HOP C-ON ;

: HELP  CR ." A B C NUM HOP" CR
           ." A, B, C should be 10000 * what Dewdney says."
           CR ;

: SIGNIT RANDOM 100 MOD 50 < IF NEGATE THEN ;

: TEST RANDOM 500 / SIGNIT
       RANDOM 500 / SIGNIT
       RANDOM 500 / SIGNIT
                     HOPALONG ;
: REDO _SCALE ! LOWRES C-OFF 1 _COLOR ! 1 SETCOLOR HOP C-ON ;
: WHAT? CR _A @ ." A=" . CR
           _B @ ." B=" . CR
           _C @ ." C=" . CR ;

{  1000 -2807 -1584 -30435 HOPALONG }
{  1500 6865 8401 -26698 HOPALONG }
{  1000 29368 -9196 -25259 HOPALONG }
  1000 7988 22297 -1381 HOPALONG

EXIT



