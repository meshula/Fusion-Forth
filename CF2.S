
*
*     BEGIN
*
   dc.b $c5
   dc.b 'BEGIN'
   dc.l blanks-12

begin bra doColon
   dc.l qComp,backMark,exit

*
*     BEGCASE  starts off a case statement
*
   dc.b $c7
   dc.b 'BEGCASE'
   dc.l begin-10

begCase bra doColon
   dc.l qComp,zero,exit

*
*     CASE
*
   dc.b $c4
   dc.b 'CASE',0
   dc.l begCase-12

case bra doColon
   dc.l dup,zbranch,1$,toResolve
1$ dc.l exit

*
*     OF
*
   dc.b $c2
   dc.b 'OF',0
   dc.l case-10

of bra doColon
   dc.l lit,over,comma,lit,equal,comma,lit,zbranch,comma
   dc.l toMark,lit,drop,comma,exit

*
*     ELSECASE
*
   dc.b $c8
   dc.b 'ELSECASE',0
   dc.l of-8

elseCase bra doColon
   dc.l toResolve,lit,drop,comma,exit

*
*     ;;
*
   dc.b $c2
   dc.b ';;',0
   dc.l elseCase-14

semiSemi bra doColon
   dc.l lit,branch,comma,toMark,doSwap,exit

*
*     ENDCASE
*
   dc.b $c7
   dc.b 'ENDCASE'
   dc.l semiSemi-8

endCase bra doColon
1$ dc.l dup,zbranch,2$
   dc.l toResolve,branch,1$
2$ dc.l drop,exit

*
*     BRANCH
*
   dc.b $86
   dc.b 'BRANCH',0
   dc.l endCase-12

branch move.l (a5),a5   ; get new IP
   adda.l a4,a5
   doNext

*
*  BUFFSIZE ( --- addr )
*
   dc.b $88
   dc.b 'BUFFSIZE',0
   dc.l branch-12

bSize dc.w $41fa,bSize0-*
* lea bSize0(PC),a0
 move.l a0,-(a7)
 doNext

*
*     C@ ( addr --- n )
*
   dc.b $82
   dc.b 'C@',0
   dc.l bSize-14

cFetch   move.l (a7)+,a0 ; get fetch address
   clr.l d0        ; zap d0
   move.b (a0),d0  ; fetch the byte
   move.l d0,-(a7) ; and push it
   doNext

*
*     C! ( n addr --- )
*
   dc.b $82
   dc.b 'C!',0
   dc.l cFetch-8

cStore   move.l (a7)+,a0  ; get store address
   move.l (a7)+,d0  ; get byte
   move.b d0,(a0)   ; and store it
   doNext

*
*     CFA  ( addr1 --- addr2 ) get CFA from PFA addr1.
*
   dc.b $83
   dc.b 'CFA'
   dc.l cStore-8

cfa   subq.l #4,(a7)
   doNext

*
*     CMOVE ( addr1 addr2 n --- ) move n bytes from addr1 to addr2
*                     start from bottom address, then work up
   dc.b $85
   dc.b 'CMOVE'
   dc.l cfa-8

cMove move.l (a7)+,d0      ; get count of bytes
      move.l (a7)+,a1      ; get dest addr
      move.l (a7)+,a0      ; get source addr
      bra.s 2$
1$    move.b (a0)+,(a1)+   ; move a byte
2$    dbra d0,1$           ; loop
      doNext               ; and finee

*
*     CMOVE> ( addr1 addr2 n --- ) move n bytes from addr1 to addr2
*                starting from the top address, then working down.
   dc.b $86
   dc.b 'CMOVE>',0
   dc.l cMove-10

cMoveB move.l (a7)+,d0 ; get count of bytes
      move.l (a7)+,a1  ; get dest addr
      adda.l d0,a1     ; and point to end of dest
      move.l (a7)+,a0  ; get source addr
      adda.l d0,a0     ; and point to end of source

      tst.l d0         ; if bytes to move is 0, skip the move
      beq.s 2$

      subq.l #1,d0     ; move one less byte than spec'd
1$    move.b -(a0),-(a1)
      dbeq d0,1$
2$    doNext

*
*     COMPILE  ( COMPILE <name1> ... )  Compile a pointer to <name1>
*                        at the current top of dictionary during runtime
   dc.b $87
   dc.b 'COMPILE'
   dc.l cMoveB-12

compile dc.l nextFree+$41ec0000
*  lea nextFree(a4),a0
   move.l (a0),a1      ; HERE
   move.l (a5)+,(a1)+  ; get address to be compiled, compile, inc HERE
   move.l a1,(a0)      ; store HERE
   doNext

*
*     [COMPILE]  : <name> ... [COMPILE] <name1> ... ;
*            force compilation of immediate word <name1> into <name>
   dc.b $c9
   dc.b '[COMPILE]'
   dc.l compile-12

bracCompile bra doColon
   dc.l dashFind,zeroEq,five,qError
   dc.l drop,cfa,org,minus,comma,exit

*
*     CONSTANT  n CONSTANT <name>  whenever <name> is subsequently
*            ( n -- )       invoked, it will leave n on the stack.
   dc.b $88
   dc.b 'CONSTANT',0
   dc.l bracCompile-14

constant bra doColon
   dc.l create,latest,pfa,four,minus,dp,store
   dc.l lit,$2f3c,wComma,comma  ; compile move.l #n,-(a7)
   dc.l lit,$265dd7cc,comma,lit,$4ed3,wComma ; compile doNext
   dc.l exit

*
*     COUNT ( addr1 >>> addr2 n ) leave addr2 of first char, and count n
*                                    for text string at addr1
   dc.b $85
   dc.b 'COUNT'
   dc.l constant-14

count bra doColon
   dc.l dup,onePlus,doSwap,cFetch,exit

*
*     CR   outputs carriage return linefeed
*
   dc.b $82
   dc.b 'CR',0
   dc.l count-10

cr bra doColon
   dc.l lit,13,emit,lit,10,emit,exit

*
*     CREATE
* create a def'n based on next word in text stream

   dc.b $86
   dc.b 'CREATE',0
   dc.l cr-8

create bra doColon
   dc.l here,doEven,dp,store ; make sure HERE is for real - even
   dc.l bl,word   ; copy next word from input stream, and allot it
   dc.l here,onePlus,cFetch,zeroEq,four,qError ; test for redefining null
   dc.l here,dup,dup,cFetch,width,fetch,min,onePlus,allot
   dc.l lit,$80,toggle,here,doEven,dp,store  ; point to LFA
   dc.l latest,org,minus,comma              ; put link into LFA
   dc.l current,fetch,store                ; save NFA as LATEST
   dc.l lit,$4eec0000+doColon,comma       ; COMPILE doColon
   dc.l lit,aVara,comma                  ; compile a pointer to <VAR>
   dc.l exit

*
*     CSP
* retuns address of user variable pointing to current parameter stack
*
   dc.b $83
   dc.b 'CSP'
   dc.l create-12

csp bra doColon
   dc.l aVara,0

*  dc.l s0+$41ec0000
**  lea s0(a4),a0
*   move.l a0,-(a7)
*   doNext

*
*     CURRENT ( --- addr )  returns a pointer to a pointer to the most
*                             recently compiled defn
   dc.b $87
   dc.b 'CURRENT'
   dc.l csp-8

current  dc.l goBetween+$41ec0000
*  lea goBetween(a4),a0
   move.l a0,-(a7)
   doNext

goBetween dc.l latestDef

*
*     DECIMAL
*  : DECIMAL 10 BASE ! ;

   dc.b $87
   dc.b 'DECIMAL'
   dc.l current-12

decimal  dc.l numBase+$41ec0000
*  lea numBase(a4),a0
   move.l #10,(a0)
   doNext

*
*     DEPTH ( --- n )  returns depth of stack before DEPTH was executed.
*
   dc.b $85
   dc.b 'DEPTH'
   dc.l decimal-12

depth dc.l s0+$41ec0000
*  lea s0(a4),a0
   move.l (a0),d0
   movea.l a7,a0
   sub.l a0,d0
   asr.l #2,d0
   move.l d0,-(a7)
   doNext

*
*     DIGIT  ( c base --- n1 tf )  successful conversion
*            ( c base --- ff    ) unsuccessful conversion
   dc.b $85
   dc.b 'DIGIT'
   dc.l depth-10

digit move.l (a7)+,d1 ; get base
    move.l (a7)+,d0    ; get char to convert
    cmpi.b #$41,d0     ; is d0 >"A"?
    blt.s 1$           ; br if not

    subq.l #7,d0       ; else sub 7 from char to convert it
    bra.s 3$           ; go convert it

1$: cmpi.b #$2f,d0     ; is d0 > "0"-1 ?
    bgt.s 2$           ; yes, go continue checking
    clr.l d1           ; set false flag
    bra.s 5$           ; and exit

2$: cmpi.b #$3a,d0     ; is also d0 <"9"+1 ?
    blt.s 3$           ; if yes, go convert
    clr.l d1           ; set false flag
    bra.s 5$           ; and exit

3$: subi.l #$30,d0     ; subtract 30 to convert ASCII to hex
    cmp.l d0,d1        ; is base > new digit?
    sgt d1             ; if new digit good set d1
    andi.l #1,d1
    beq.s 5$           ; branch if digit no good

    move.l d0,-(a7)    ; push good digit
5$: move.l d1,-(a7)    ; push flag

    doNext             ; and exit

*
*     DO
*
   dc.b $c2
   dc.b 'DO',0
   dc.l digit-10

do bra doColon
   dc.l qComp,compile,adoa,backMark,exit 

*
*     DP ( -- addr ) returns address pointing to next free area
*
   dc.b $82
   dc.b 'DP',0
   dc.l do-8

dp dc.l nextFree+$41ec0000 ; see next line
*  lea nextFree(a4),a0
   move.l a0,-(a7)
   doNext

*
*     DROP  ( n --- )
*
   dc.b $84
   dc.b 'DROP',0
   dc.l dp-8

drop   addq.l #4,a7
   doNext

*
*  2DROP ( n1 n2 --- )
*
   dc.b $85
   dc.b '2DROP'
   dc.l drop-10

twoDrop addq.l #8,a7
 doNext

*
*   3DROP ( n1 n2 n3 --- )
*
   dc.b $85
   dc.b '3DROP'
   dc.l twoDrop-10

threeDrop addq.l #4,a7
 addq.l #8,a7
 doNext

*
*     DUP  ( n -- n n )
*
   dc.b $83
   dc.b 'DUP'
   dc.l threeDrop-10

dup   move.l (a7),-(a7)
   doNext

*
*  2DUP ( n1 n2 --- n1 n2 n1 n2 )
*
   dc.b $84
   dc.b '2DUP',0
   dc.l dup-8

twoDup move.l 4(a7),-(a7) ; copy n2,
  move.l 4(a7),-(a7)      ; now n1.
  doNext

*
* 3DUP ( n1 n2 n3 --- n1 n2 n3 n1 n2 n3 )
*
   dc.b $84
   dc.b '3DUP',0
   dc.l twoDup-10

threeDup move.l 8(a7),-(a7) ; copy n1
 move.l 8(a7),-(a7) ; copy n2
 move.l 8(a7),-(a7) ; copy n3
 doNext

*
*    ?DUP ( n -- n n ) or ( 0 -- 0 )
*
   dc.b $84
   dc.b '?DUP',0
   dc.l threeDup-10

qdup move.l (a7),d0 ; get top value from stack
 beq.s 1$           ; if value is zero, exit
   move.l d0,-(a7)  ; else dup the value
1$ doNext           ; and exit

*
*     ELSE
*
   dc.b $c4
   dc.b 'ELSE',0
   dc.l qdup-10

else bra doColon
   dc.l compile,branch,toMark,doSwap,toResolve,exit

*
*     EMIT    ( n --- ) sends char n to current output device(s)
*
   dc.b $84
   dc.b 'EMIT',0
   dc.l else-10

emit:
   move.l (a7)+,d0 ; get char to print
   bsr charOut
   doNext

*
*     ENCLOSE ( addr1 c --- addr1 n1 n2 n3 ) scan starting at addr1 for
*          first c delimited word. Leave addr1, byte offset to first
*            non-delimiter, the following delimiter, and first unscanned char
   dc.b $87
   dc.b 'ENCLOSE'
   dc.l emit-10

enclose move.l (a7)+,d0 ; get delimiter
        move.l (a7)+,a0 ; get addr
        move.l a0,a1    ; and preserve it for later
        clr.l d1        ; clear offset to first non-delim
        clr.l d2        ; clear offset to following delim
        clr.l d3        ; clear offset to first nonscanned char

1$:      tst.b (a0)     ; is value null (eol)?
         beq.s 3$       ; if yes, goodbye
         cmp.b (a0)+,d0 ; is byte at a0 a delimiter?
         bne.s 2$       ; br if not
         addq.w #1,d1   ; inc offset to 1st nd
         addq.w #1,d2   ; inc offset to next delim
         addq.w #1,d3   ; inc offset to 1st nonscanned
         bra.s 1$       ; and keep looking for non delimiter

2$:      tst.b (a0)     ; is value null (eol)?
         beq.s 3$       ; if yes, goodbye
         cmp.b (a0)+,d0 ; is byte at a0 a delimiter?
         beq.s 3$       ; br if delimiter
         addq.w #1,d2   ; inc offset to next delim
         addq.w #1,d3   ; inc to 1st nonscanned
         bra.s 2$

3$:      addq.w #2,d3   ; point to 1st nonscanned
         addq.w #1,d2

       move.l a1,-(a7) ; leave addr1
       move.l d1,-(a7) ; leave byte offset to 1st nondelimiter
       move.l d2,-(a7) ; leave offset to next delimiter
       move.l d3,-(a7) ; leave offset to 1st nonscanned

   doNext             ; and exit

*
*     ERROR   ( n -- )
*
   dc.b $85
   dc.b 'ERROR'
   dc.l enclose-12

error bra doColon
   dc.l two,vIn,store
   dc.l space,here,count,type,adotqa
   dc.b 2,' ?'
   EVEN
   dc.l spStore
   dc.l tib,fetch,org,lessThan,zbranch,1$
   dc.l tib,fetch,toIn,fetch,plus
   dc.l vmark,store,one,vy,store
1$ dc.l quit,exit

*
*     EVEN  ( n --- n2 )  makes n even
*
   dc.b $84
   dc.b 'EVEN',0
   dc.l error-10

doEven move.l (a7),d0
    bclr #0,d0          ; is number even?
    beq.s 1$            ; if yes, exit
    addq.l #1,(a7)      ; else even out number
1$: doNext

*
*     EXECUTE ( addr --- )
*
   dc.b $87
   dc.b 'EXECUTE'
   dc.l doEven-10

execute  move.l (a7)+,a3 ; get cfa of word to execute, a ptr to executable code
   jmp (a3)

*
*     FENCE ( --- addr ) variable containing end of protected dictionary
*
   dc.b $85
   dc.b 'FENCE'
   dc.l execute-12

fence bra doColon
   dc.l aVara,lastWord

*
*     FILL ( addr n b --- )  fill n bytes at addr with b
*
   dc.b $84
   dc.b 'FILL',0
   dc.l fence-10

fill    move.l (a7)+,d0  ; get b
    move.l (a7)+,d1  ; get n
    move.l (a7)+,a0  ; get addr
    bra.s 2$
1$: move.b d0,(a0)+  ; store b, incr addr
2$: dbf d1,1$
    doNext

*
*     GEMDOS ( params # of words --- result )
*
   dc.b $86
   dc.b 'GEMDOS',0
   dc.l fill-10

gemdos move.l (a7)+,d7 ; get number of words on the stack
      add.l d7,d7      ; * 2
      trap #1          ; call the GEMDOS
      add.l d7,a7      ; fix the stack
      move.l d0,-(a7)  ; return a value
      doNext

*
*    GETREZ ( --- n ) returns 0=lo 1=med 2=hires
*
   dc.b $86
   dc.b 'GETREZ',0
   dc.l gemdos-12

getRez move.w #4,-(a7)
   trap #14
   addq.l #2,a7
   move.l d0,-(a7)
   dc.w $41fa,_rez-2-*
*  lea _rez(PC),a0
   move.l d0,(a0)       ; save screen resolution in system variable
   doNext

*
*    GOTOXY ( x y --- ) positions cursor at x,y
*
   dc.b $86
   dc.b 'GOTOXY',0
   dc.l getRez-12

gotoXY:
   dc.w $41fa,vOut2-*-2+8
   move.l (a0),d0    ; get output device
   cmp.w #99,d0      ; is it proportional?
   beq.s 2$          ; br if yes

   dc.w $41fa,vOut1-*-2+8
   move.l (a0),d0    ; get output device
   cmp.w #99,d0      ; is it proportional?
   bne.s 1$          ; if no, don't do this

2$ dc.w $41fa,pdata-*-2
   move.l (a7),d0    ; what is Y?
   move.l 8(a0),a1   ; get address of font
   move.w (a1),d1    ; get height of font
   mulu d0,d1        ; multiply height*y to get pixel line
   move.w 6(a0),d2   ; get leading
   mulu d0,d2        ; multiply lead*y
   add.w d2,d1       ; target y
   move.w d1,2(a0)   ; store y

   move.l 4(a7),d0   ; get x
   asl.w #3,d0       ; times 8
   move.w d0,2(a0)   ; save x
   doNext            ; prop is done already.

1$ move.w #27,d0
   bsr charOut
   move.w #$59,d0
   bsr charOut
   move.l (a7)+,d0
   add.w #$20,d0
   bsr charOut
   move.l (a7)+,d0
   add.w #$20,d0
   bsr charOut
   doNext

*
*    HERE  ( --- n )  returns address of next avail dict locn
*
   dc.b $84
   dc.b 'HERE',0
   dc.l gotoXY-12

here   dc.l nextFree+$41ec0000 ; see next line
*  lea nextFree(a4),a0
   move.l (a0),-(a7)
   doNext

*
*    HEX   sets numeric base to hexadecimal
*
   dc.b $83
   dc.b 'HEX'
   dc.l here-10

hex bra doColon
   dc.l lit,16,base,store,exit

*
*     I   ( --- n ) copies current index of inner loop; ie: 1st value on
*                      return stack
   dc.b $81
   dc.b 'I'
   dc.l hex-8

i   move.l (a6),-(a7)
   doNext

*
*     I' ( -- n ) returns limit value of inner loop; ie: 2nd value on
*                   return stack
   dc.b $82
   dc.b 'I''',0
   dc.l i-6

iPrime move.l 4(a6),-(a7)
   doNext

*
*     IF
*
   dc.b $c2
   dc.b 'IF',0
   dc.l iPrime-8

doIf bra doColon
   dc.l qComp,compile,zbranch,toMark,exit

*
*     IMMEDIATE  makes latest definition an immediate word
*
   dc.b $89
   dc.b 'IMMEDIATE'
   dc.l doIf-8

immediate bra doColon
   dc.l latest,lit,64,toggle,exit

*
*     INTERPRET  interpret the text pointed to by inPtr
*
   dc.b $89
   dc.b 'INTERPRET'
   dc.l immediate-14

interpret bra doColon
0$: dc.l dashFind
    dc.l zbranch          ; : INTERPRET BEGIN -FIND
    dc.l 2$               ;      IF STATE @ <
    dc.l state,fetch,lessThan,zbranch   ; test precedence bit
    dc.l 1$               ;         IF  CFA , ; if set, compile
    dc.l cfa,org,minus,comma
    dc.l branch
    dc.l 3$ 

1$: dc.l cfa,execute     ;           ELSE CFA EXECUTE
    dc.l branch          ;         THEN
    dc.l 3$

2$: dc.l here,number     ;  else convert string to number if possible
    dc.l state,fetch,zerogt,zbranch
    dc.l 3$              ; if compiling, compile "LIT" and number.
    dc.l lit,lit,comma,comma

3$: dc.l qStack          ; issue an error if stack is out of bounds
    dc.l branch          ;   AGAIN  ;
    dc.l 0$
    dc.l exit

*
*     J   ( --- n ) copies current counter of outside loop to stack
*                    ie: 3rd value on return stack
   dc.b $81
   dc.b 'J'
   dc.l interpret-14

j   move.l 8(a6),-(a7)
   doNext

*
*     J' ( -- n ) copies limit of outside loop. ie: 4th value on return stack
*
   dc.b $82
   dc.b 'J''',0
   dc.l j-6

jPrime move.l 16(a6),-(a7)
   doNext

*
*     KEY ( --- n ) n 0-255 is ASCII, >255 is special character
*
   dc.b $83
   dc.b 'KEY'
   dc.l jPrime-8

key bsr charIn
   bra.s 2$

   move.w #2,-(a7) ; console
   move.w #2,-(a7)  ; bconin function call
   trap #13         ; call BIOS
   addq.l #4,a7     ; adjust stack

   tst.w d0         ; 0 in low word?
   bne.s 1$         ; branch if no
   clr.w d0
   swap d0
   add.l #256,d0    ; convert to scraggly weird numbers
   bra.s 2$

1$ and.l #255,d0   ; clear other weird BIOS bitz
2$ move.l d0,-(a7)
   doNext

*
*     L>W    ( 32n --- 16n ) converts a long to a word
*
   dc.b $83
   dc.b 'L>W'
   dc.l key-8

lToW addq.l #2,a7 ; destroy upper word of 32n.
     doNext

*
*     LATEST ( --- n ) returns NFA of most recently compiled word
*
   dc.b $86
   dc.b 'LATEST',0
   dc.l lToW-8

latest
* dc.l $486c0000+latestDef
*  pea latestDef(a4)
*   doNext

   dc.l $41ec0000+latestDef
*  lea latestDef(a4),a0
   move.l (a0),-(a7)  ; fetch pointer to latest defn
   doNext

*
*     LIT
* compiled as the runtime to move an inline literal to the stack

   dc.b $83
   dc.b 'LIT'
   dc.l latest-12

lit move.l (a5)+,-(a7)   ; get value >>> by ip onto stack
   doNext

*
*  LITERAL ( n --- ) immediate word to compile a literal n
*
   dc.b $c7
   dc.b 'LITERAL'
   dc.l lit-8

literal bra doColon
   dc.l state,fetch,zbranch,1$
   dc.l lit,lit,comma,comma
1$ dc.l exit

*
*     LOOP
*
   dc.b $c4
   dc.b 'LOOP'
   dc.l literal-12

loop bra doColon
   dc.l compile,aloopa,backResolve,exit

*
*     MAX     ( n1 n2 --- n-max )
*
   dc.b $83
   dc.b 'MAX'
   dc.l loop-10

max    move.l (a7)+,d0 ; get n2
    move.l (a7),d1  ; get n1
    cmp.l d0,d1     ; n2 > n1?
    ble.s 1$        ; br if no
    exg.l d0,d1     ; yes, doSwap 'em
1$: move.l d0,(a7)  ; biggest one back on stack
    doNext

*
*     MIN      ( n1 n2 -- n-min )
*
   dc.b $83
   dc.b 'MIN'
   dc.l max-8

min    move.l (a7)+,d0 ; get n2
    move.l (a7),d1  ; get n1
    cmp.l d0,d1     ; n1 > n2?
    bge.s 1$
    exg.l d0,d1     ; yes, doSwap
1$: move.l d0,(a7)
    doNext

*
*  MOVE ( addr1 addr2 n --- )
*
   dc.b $84
   dc.b 'MOVE',0
   dc.l min-8

doMove move.l (a7)+,d0 ; get count
 move.l (a7)+,a1  ; get dest
 move.l (a7)+,a0  ; get source
 bra.s 2$

1$ move.l (a0)+,(a1)+
2$ dbra d0,1$

 doNext

*
*     NEGATE ( n >>> -n )
*
   dc.b $86
   dc.b 'NEGATE',0
   dc.l doMove-10

negate neg.l (a7)
   doNext

*
*     NFA   ( CFA --- NFA )
*
   dc.b $83
   dc.b 'NFA'
   dc.l negate-12

nfa bra doColon
   dc.l lit,5,minus ; point to last char of name
1$ dc.l lit,1,minus,dup,cFetch ; get next previous char
   dc.l lit,127,doSwap,lessThan,zbranch,1$
   dc.l exit

*
*     NOT     ( n --- f ) returns true if n is 0
*
   dc.b $83
   dc.b 'NOT'
   dc.l nfa-8

doNot tst.l (a7)
   seq d0
   andi.l #1,d0
   move.l d0,(a7)
   doNext

*
*     NUMBER  ( addr --- n ) convert string at addr to n
*
   dc.b $86
   dc.b 'NUMBER',0
   dc.l doNot-8

number bra doColon
    dc.l lit,0,doSwap,dup,onePlus,cFetch      ; is first char a "-"?
    dc.l lit,$2d,equal,dup,toR,plus,aNumbera  ; if yes, save it for later
    dc.l cFetch,dup,bl,notEqual,zbranch,2$    ; is next char blank? br if yes
    dc.l zero,notEqual,zbranch,2$             ; is next char null? br if yes

1$  dc.l error ; report the error and quit

2$  dc.l drop,rFrom,zbranch,3$                ; was a minus on the rtn stack?
    dc.l negate                               ; if yes, negate number
3$  dc.l exit

*
*     ODD     ( n --- f )  returns true if n is odd
*
   dc.b $83
   dc.b 'ODD'
   dc.l number-12

odd andi.l #1,(a7)
    doNext

*
*     OR      ( n1 n2 --- result )
*
   dc.b $82
   dc.b 'OR',0
   dc.l odd-8

doOr   move.l (a7)+,d0
   or.l d0,(a7)
   doNext

*
*     ORG     ( --- addr ) returns absolute base address of FORTH
*
   dc.b $83
   dc.b 'ORG'
   dc.l doOr-8

org move.l a4,-(a7)
   doNext

*
*     OVER    ( n1 n2 --- n1 n2 n1 )
*
   dc.b $84
   dc.b 'OVER',0
   dc.l org-8

over   move.l 4(a7),-(a7)
   doNext

*
*     PAGE
*  clears the screen

   dc.b $84
   dc.b 'PAGE',0
   dc.l over-10

clrPage  bra doColon   ; : PAGE 27 EMIT 69 EMIT ;
      dc.l lit       ; push 27 on the stack
      dc.l 27,emit,lit,69,emit,exit

*
*     PFA  ( addr1 --- addr2 ) returns pfa of defn whose name starts at addr1
*
   dc.b $83            ;   : PFA DUP C@ 1F AND SWAP 1+ + EVEN 8 + ;
   dc.b 'PFA'
   dc.l clrPage-10

pfa bra doColon
   dc.l dup,cFetch,lit,$1f,doAnd,doSwap,onePlus,plus,doEven,lit,8,plus,exit

*
*     PICK ( n1 -- n2 ) returns the nth item on the stack, where the first
*                         item is item # 0.
   dc.b $84
   dc.b 'PICK',0
   dc.l pfa-8

pick bra doColon
   dc.l onePlus,fourTimes,spFetch,plus,fetch,exit

*
*     QUERY get keyboard input
*
   dc.b $85
   dc.b 'QUERY'
   dc.l pick-10

query bra doColon
   dc.l lit,inBuffer,org,plus,lit,79,expect,zero,toIn,store,exit

*
*     QUIT   restart the interpreter loop
*
   dc.b $84
   dc.b 'QUIT',0
   dc.l query-10

quit bra doColon
   dc.l lbrac       ; suspend compilation
   dc.l lit,inBuffer,org,plus,tib,store ; make input from console

1$ dc.l rpStore    ; clear return stack
   dc.l cr,query    ; get chars from terminal
   dc.l interpret   ; interpret the text

   dc.l adotqa
   dc.b 3
   dc.b ' OK'
   EVEN

   dc.l branch      ; go back for more
   dc.l 1$
   dc.l exit

*
*     R@  ( --- n ) get a copy of the top of the return stack
*
   dc.b $82
   dc.b 'R@',0
   dc.l quit-10

rFetch   move.l (a6),-(a7)
   doNext

*
*     R0 ( --- addr ) variable containing initial rsp
*
   dc.b $82
   dc.b 'R0',0
   dc.l rFetch-8

rZero dc.w $41fa,rsp-*-2
* lea rsp(PC),a0
   move.l a0,-(a7)
   doNext

*
*     REPEAT
*
   dc.b $c6
   dc.b 'REPEAT',0
   dc.l rZero-8

repeat bra doColon
   dc.l compile,branch,doSwap,backResolve,toResolve,exit

*
*     ROT  ( n1 n2 n3 -- n2 n3 n1 )
*
   dc.b $83
   dc.b 'ROT'
   dc.l repeat-12

rot move.l (a7)+,d1   ; >D1
   move.l (a7),d0     ; SWAP
   move.l 4(a7),(a7)
   move.l d0,4(a7)
   move.l d1,-(a7)    ; D1>
   move.l (a7),d0     ; SWAP
   move.l 4(a7),(a7)
   move.l d0,4(a7)
   doNext

*
*     RP@ ( --- addr ) get current value of return stack pointer
*
   dc.b $83
   dc.b 'RP@'
   dc.l rot-8

rpFetch move.l a6,-(a7)
   doNext

*
*     RP!  ( -- )  initialize return stack
*
   dc.b $83
   dc.b 'RP!'
   dc.l rpFetch-8

rpStore dc.l $41ec0000+rsp
*  lea rsp,a0
   move.l (a0),a6
   doNext

*
*     S0  ( -- addr ) returns a pointer to the user variable
*               containing the initial stack value
   dc.b $82
   dc.b 'S0',0
   dc.l rpStore-8

sZero dc.l $41ec0000+s0
* lea s0(a4),a0
   move.l a0,-(a7)
   doNext
*
* SMUDGE
*
   dc.b $86
   dc.b 'SMUDGE',0
   dc.l sZero-8

smudge bra doColon
   dc.l latest,lit,$20,toggle,exit

*
*     SP@ returns current value of stack pointer
*
   dc.b $83
   dc.b 'SP@'
   dc.l smudge-12

spFetch  move.l a7,-(a7)
      doNext
*
*     SP!  initialize parameter stack to value found in S0
*
   dc.b $83
   dc.b 'SP!'
   dc.l spFetch-8

spStore   dc.l s0+$2e6c0000 ; see next line
*  movea.l s0(a4),a7
   doNext

*
*     SPACE  outputs a blank
*
   dc.b $85
   dc.b 'SPACE'
   dc.l spStore-8

space:
   move.w #$20,d0
   bsr charOut
   doNext

* bra doColon
*   dc.l lit,32,emit,exit

*
*     SPACES ( n -- ) outputs n spaces
*
   dc.b $86
   dc.b 'SPACES',0
   dc.l space-10

spaces bra doColon
   dc.l lit,0,max,dup,zbranch,2$ ; make sure n > 0
   dc.l lit,0,adoa
1$ dc.l space,aloopa,1$,exit

2$ dc.l drop,exit

*
*     SQRT  ( n1 -- n2 ) returns integer square root of 32 bit n1
*
   dc.b $84
   dc.b 'SQRT',0
   dc.l spaces-12

sqrt move.l (a7),d0 ; get number to scroot
   tst.l d0         ; skip doing zero
   bne.s 1$
   doNext

1$ cmp.l #$10000,d0 ; if long word, use long routine
   bge.s qlsqrt
   cmp.w #625,d0    ; would short routine be quicker?
   bhi.s qsqrt      ; no, use general purpose routine

*  this first routine is optimized for small 16 bit n's

   move.w #-1,d1
2$ addq.w #2,d1
   sub.w d1,d0
   bpl 2$
   asr.w #1,d1
   andi.l #$ffff,d1
   move.l d1,(a7)
   doNext

*  this routine is general for 16 bit n's.

qsqrt move.w #7,d4   ; loop count
   clr.w d1          ; 0 error term
   clr.w d2
3$ add.w d0,d0       ; get 2 leading bits at a time and add
   addx.w d1,d1      ; into error term for interpolation
   add.w d0,d0       ; (classical method)
   addx.w d1,d1
   add.w d2,d2       ; running estimate * 2
   move.w d2,d3
   add.w d3,d3
   cmp.w d3,d1
   bls.s 4$          ; new error term > 2* running estimate?
   addq.w #1,d2      ; yes, want a '1' bit then
   addq.w #1,d3      ; fix up new error term
   sub.w d3,d1
4$ dbra d4,3$        ; do all 8 bit-pairs
   andi.l #$ffff,d2
   move.l d2,(a7)
   doNext

* 32 to 16 bit square root

qlsqrt moveq #13,d4  ; loop count
   moveq #0,d1       ; error term
   moveq #0,d2
5$ add.l d0,d0       ; get 2 leading bits at a time and add
   addx.w d1,d1
   add.l d0,d0
   addx.w d1,d1
   add.w d2,d2
   move.w d2,d3
   add.w d3,d3
   cmp.w d3,d1
   bls.s 6$
   addq.w #1,d2
   addq.w #1,d3
   sub.w d3,d1
6$ dbra d4,5$

   add.l d0,d0
   addx.w d1,d1
   add.l d0,d0
   addx.l d1,d1
   add.w d2,d2
   move.l d2,d3
   add.w d3,d3
   cmp.l d3,d1
   bls.s 7$
   addq.w #1,d2
   addq.w #1,d3
   sub.l d3,d1

7$ add.l d0,d0
   addx.l d1,d1
   add.l d0,d0
   addx.l d1,d1
   add.w d2,d2
   move.l d2,d3
   add.l d3,d3
   cmp.l d3,d1
   bls.s 8$
   addq.w #1,d2
8$ andi.l #$ffff,d2
   move.l d2,(a7)
   doNext

*
*     STARTWORD ( --- addr ) returns address of pointer to first word to run
*
   dc.b $89
   dc.b 'STARTWORD'
   dc.l sqrt-10

startWord dc.w $41fa,firstWord-*-2
* lea firstWord(PC),a0
   move.l a0,-(a7)
   doNext

*
*     STATE  ( -- addr ) returns address of compilation state flag
*
   dc.b $85
   dc.b 'STATE'
   dc.l startWord-14

state  dc.l compState+$41ec0000
*  lea compState(a4),a0
   move.l a0,-(a7)
   doNext

*
*     SWAP     ( n1 n2 --- n2 n1 )
*
   dc.b $84
   dc.b 'SWAP',0
   dc.l state-10

doSwap   move.l (a7),d0
   move.l 4(a7),(a7)
   move.l d0,4(a7)
   doNext

*
*     THEN     immediate word to terminate a conditional
*
   dc.b $c4
   dc.b 'THEN',0
   dc.l doSwap-10

then bra doColon
   dc.l toResolve,exit

*
*     TIB  ( --- addr ) returns a pointer to The Input Buffer
*
   dc.b $83
   dc.b 'TIB'
   dc.l then-10

tib dc.l inPtr+$41ec0000
*  lea inPtr(a4),a0
   move.l a0,-(a7)
   doNext

*
*     TOGGLE ( addr b -- ) toggles bits b of (addr)
*
   dc.b $86
   dc.b 'TOGGLE',0
   dc.l tib-8

toggle   move.l (a7)+,d0 ; get bits to toggle
   move.l (a7)+,a0 ; address to be toggled
   eor.b d0,(a0)   ; toggle the bits
   doNext    ; and exit

*
*     TYPE  ( addr n --- ) type message at addr of n chars
*
   dc.b $84
   dc.b 'TYPE',0
   dc.l toggle-12

type move.l (a7)+,d0 ; get count of chars to output
     move.l (a7)+,a0 ; get address to output from
     movem.l a3-a6,-(a7) ; save some important registers

       bra.s 2$       ; start the loop

1$     clr.w d1
       move.b (a0)+,d1
         move.l a0,-(a7) ; save for later
         move.l d0,-(a7) ; ditto

           move.w d1,d0
           bsr charOut   ; print character in d0

         move.l (a7)+,d0 ; restore loopys
         move.l (a7)+,a0

2$    dbra d0,1$     ; loop for more

     movem.l (a7)+,a3-a6 ; get those important registers back
     doNext

*
*  U<  ( u1 u2 -- f )
*
   dc.b $82
   dc.b 'U<',0
   dc.l type-10

uLess move.l (a7)+,d0
 cmp.l (a7),d0
 bhi.s 1$
 clr.l (a7) ; false
 doNext
1$ moveq.l #1,d0
 move.l d0,(a7)
 doNext

*
*     UNTIL
*
   dc.b $c5
   dc.b 'UNTIL'
   dc.l uLess-8

until bra doColon
   dc.l compile,zbranch,backResolve,exit

*
*     W>L
*
   dc.b $83
   dc.b 'W>L'
   dc.l until-10

wToL subq.l #2,-(a7) ; make n into a long
  move.l (a7),d0
  ext.l d0           ; adjust the sign.
  move.l d0,(a7)
  doNext

*
*     WHILE
*
   dc.b $c5
   dc.b 'WHILE'
   dc.l wToL-8

while bra doColon
   dc.l doIf,exit

*
*     WIDTH ( --- $1f ) puts length of longest word on stack
*
   dc.b $85
   dc.b 'WIDTH'
   dc.l while-10

width dc.l maxLength+$41ec0000
*  lea maxLength(a4),a0
   move.l a0,-(a7)
   doNext

*
*     WORD ( c --- )
*
   dc.b $84
   dc.b 'WORD',0
   dc.l width-10

word  bra doColon
   dc.l tib,fetch,toIn,fetch,plus ; calc addr of next char to search
   dc.l doSwap,enclose            ; search thru text until char c
   dc.l here,lit,40,blanks        ; clear out some space
   dc.l toIn,plusStore            ; inc input offset
   dc.l over,minus                ; get length of string
   dc.l toR,rFetch                ; copy length for later
   dc.l here,cStore               ; compile count
   dc.l plus                      ; address of first nondelim
   dc.l here,onePlus              ; get addr after compiled count
   dc.l rFrom,cMove               ; move the word into the buffer
   dc.l exit

*
*     XBIOS ( params #of words --- result )
*
   dc.b $85
   dc.b 'XBIOS'
   dc.l word-10

xbios move.l (a7)+,d7 ; get number of words on the stack
      add.l d7,d7     ; * 2
      trap #14        ; call the XBIOS
      adda.l d7,a7    ; fix stack
      move.l d0,-(a7) ; return a value
      doNext

*
*     C$    ( -- addr ) returns address of C string buffer
*
   dc.b $82
   dc.b 'C$',0
   dc.l xbios-10

cStr dc.l $41ec0000+cString
   move.l a0,-(a7)
   doNext

*
*     $>C$   ( addr n --- addr ) converts a string from FORTH format
*                to GEMDOS C format. The string is kept at PAD.
   dc.b $84
   dc.b '$>C$',0
   dc.l cStr-8

sToCs bra doColon
   dc.l cStr,lit,80,zero,fill,cStr,doSwap,cMove,cStr,exit

*
*     "  imm: ( --- addr n ) addr pointing to PAD
*
   dc.b $c1
   dc.b $22
   dc.l sToCs-10

quote bra doColon
   dc.l lit,34             ; prepare to look for a "
   dc.l state,fetch,zbranch,1$ ; interpreting or compiling?
   dc.l lit,aquotea,comma,word,here,cFetch,onePlus,allot ; compile a string
   dc.l here,doEven,dp,store,exit

1$ dc.l word,here          ; parse it and point to it
   dc.l count,toR,rFetch   ; get string length, and save for later
   dc.l pad,doSwap,cMove   ; move string into PAD
   dc.l pad,rFrom,exit     ; and return addr and count on stack

*
*     XOR ( n1 n2 --- result )
*
   dc.b $83
   dc.b 'XOR'
   dc.l quote-6

doXor   move.l (a7)+,d0
   eor.l d0,(a7)
   doNext






