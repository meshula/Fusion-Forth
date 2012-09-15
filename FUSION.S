

***************************************************************************
*                                                                         *
*  CAST FORTH   written by Nick Porcino for 68000                         *
*     a direct threaded interpreter                                       *
*                                                                         *
***************************************************************************
*                                                                         *
*      A7 = data stack pointer                                            *
*      A6 = return stack pointer                                          *
*      A5 = interpretive pointer  IP                                      *
*      A4 = absolute origin offset                                        *
*      A3 = code field pointer                                            *
*                                                                         *
***************************************************************************

buffSize equ $20000       ; 128K

doNext  MACRO
         movea.l (a5)+,a3 ; fetch cfa pointed to by ip, and inc ip
         adda.l a4,a3
         jmp (a3)         ; go execute the next word
         ENDM

EVEN     MACRO
         cnop 0,2         ; align to next word boundary
         ENDM

powerUp  movea.l a7,a5
         lea powerUp,a4      ; get relativeness of all the words
         dc.l $41fa0000-2+bigBuff-*
*        lea bigBuff(PC),a0  ; set address of big buffer
         move.l a4,(a0)      ; save address of buffer

****** relocate FORTH upwards by buffSize now:
bSize0   move.l #buffSize,d7
         tst.l d7
         beq.s continue

         move.l a4,a2        ; get starting address
         move.l a4,a1        ; calc destination address
         adda.l d7,a1

         dc.l $41fa0000-2+nextFree-*
*        lea nextFree(PC),a0 ; find how long FORTH is
         move.l (a0),d0

         adda.l d0,a2        ; calc end of dest block
         adda.l d0,a1        ; calc end of source block

         asr.l #2,d0         ; convert length to long words
         addq.l #2,d0        ; move a few extra for good measure

1$       move.l -(a2),-(a1)         ; start moving FORTH
         dbra d0,1$

         adda.l d7,a4               ; adjust FORTH base offset register
         dc.l $4eec0000+continue
*        jmp continue(a4)           ; continue starting FORTH up

**********************************************************************

continue dc.w $41fa,goFerIt-2-*     ; shift execution into super mode
*        lea goFerIt,a0
         move.l a0,-(a7)
         move.w #38,-(a7)
         trap #14
goFerIt  addq.l #6,a7               ; first super instruction

         dc.l $4ffa0000-2+parmStack-*
*        lea parmStack,a7

         dc.l $4dfa0000-2+rtnStack-*
*        lea rtnStack,a6

         dc.l $41fa0000-2+rsp-*
*        lea rsp,a0
         move.l a6,(a0)

         dc.l $41fa0000-2+s0-*
*        lea s0,a0
         move.l a7,(a0)

         dc.l $43fa0000-2+inBuffer-*
         dc.l $41fa0000-2+inPtr-*
*        lea inBuffer,a1
*        lea inPtr,a0
         move.l a1,(a0)

         dc.l $41fa0000-2+nextFree-*
*        lea nextFree,a0
         move.l (a0),a1
         adda.l a4,a1
         move.l a1,(a0)

         dc.l $41fa0000-2+latestDef-*
*        lea latestDef,a0
         move.l (a0),a1
         adda.l a4,a1
         move.l a1,(a0)     

         dc.l $43fa0000-2+goBetween-*
*        lea goBetween(PC),a1
         move.l a0,(a1)

   move.w #34,-(a7)  ; glom the mouse vector
   trap #14
   addq.l #2,a7
   add.l #16,d0
   move.l d0,a1
   dc.w $41fa,realMouse-*-2
* lea realMouse(PC),a0
   move.l (a1),(a0)   ; and put it where we can find it again

 move.w #$10,-(a7)    ; CAPS lock activate
 move.w #11,-(a7)
 trap #13             ; aye aye captain
 addq.l #4,a7

         dc.l $4bfa0000-2+firstWord-*
*        lea firstWord,a5   ; first word to execute

         doNext

doColon  move.l a5,-(a6)  ; move ip onto return stack
         move.l a3,a5     ;
         addq.l #4,a5     ; increment ip
next     doNext

* USER VARIABLE AREA

compState  dc.l 0         ; compilation state. 0 = suspended
numBase    dc.l 10        ; current number base
maxLength  dc.l $1f       ; maximum forth name length
inOffset   dc.l 0         ; offset into input stream >IN
textGunk   dc.l 0         ; pointer to PAD text area HLD
temp       dc.l 0         ; temp storage area

lineaptr   dc.l 0         ; linea vector
_scrnbase  dc.l $78000    ; address of the screen
_rez       dc.l 0         ; current screen resolution
intrnclr   dc.l 0         ; current color for use by PLOT
_startRez  dc.l 0         ; power up screen resolution

realMouse  dc.l 0         ; storage for mouse vector
mouseParam dc.b 0,0,1,1   ; mouse handler parameters
mX         dc.l 100,100   ; mouse coords
mR         dc.l 0,0       ; mouse button flags
mLclip     dc.l 50        ; mouse left clip
mRclip     dc.l 100       ; mouse right clip
mUclip     dc.l 0         ; mouse upper clip
mDclip     dc.l 199       ; mouse downer clip

bigBuff    dc.l powerUp   ; address of 200k buffer
firstWord  dc.l cold      ; first word to execute
s0         dc.l parmStack ; pointer to top of parameter stack
rsp        dc.l rtnStack  ; pointer to top of return stack
inPtr      dc.l inPtr     ; pointer to input buffer
latestDef  dc.l lastWord  ; pointer to latest definition
nextFree   dc.l forthEnd  ; beginning of user area - HERE

inBuffer   ds.b 128       ; text input buffer
cString    ds.b 80        ; cString buffer
           ds.b 1024      ; a little space for the parameter stack
parmStack  ds.b 1024      ; a little space for the return stack

rtnStack   ds.w 0

**********************************************************************
*    the language definition:                                        *
**********************************************************************

* charOut:  devices to output to are held in vOut1, and vOut2.
*           the character to output is in d0.

charOut dc.w $41fa,vOut1+8-*-2 ; get addr of out device #1
    bsr doOut                  ; go output character
    dc.w $41fa,vOut2+8-*-2     ; get addr of out device #2

doOut:
    move.w d0,-(a7)            ; save the character
    move.l (a0),d1             ; get device
    tst.w d1
    bmi.s 2$                   ; if device is null, skip

    cmp.w #2,d1                ; is it output to console?
    bne.s 4$

    move.w d0,d1               ; put char in right register
    movem.l a3-a6/d7,-(a7)
    move.l $4a8,a0             ; get output vector
    jsr (a0)                   ; output directly to screen
    movem.l (a7)+,a3-a6/d7
    move.w (a7)+,d0            ; restore character
    rts

4$  cmp.w #99,d1               ; prop out?
    bne.s 1$
    move.w (a7)+,d0
    bra propout

1$  cmp.w #5,d1                ; is it output to file?
    bgt.s 3$                   ; br if yes

    move.w d1,-(a7)            ; push device number
    move.w #3,-(a7)            ; push output code
    trap #13                   ; print character
    addq.l #4,a7               ; canx device and code
2$  move.w (a7)+,d0            ; get the character back
    rts                     

*   lea theChar,a0
3$  dc.w $41fa,theChar-*-2     ; redirect output to spec'd file
    move.w (a7),d0             ; put the character in a spot
    move.b d0,(a0)

    move.l a0,-(a7)            ; push address where the character is
    move.l #1,-(a7)            ; writing one character
    move.w d1,-(a7)            ; push handle number
    move.w #$40,-(a7)          ; push write command
    trap #1                    ; GEMDOS
    add.l #12,a7               ; fix the stack

    move.w (a7)+,d0            ; restore the character
    rts                        ; and finished

theChar dc.l 0,0               ; space to hold the character


* charIn:   input device is in vIn
*           the read character is in d0.

charIn:
    movem.l a1/d1-d4,-(a7)
    dc.w $41fa,vIn+8-*-2       ; get addr of out device #1
    move.l (a0),d4             ; get device
    tst.w d4
    bpl.s 6$                   ; if device is null, set input back to CON:

    moveq.l #2,d4
    move.l d4,(a0)

6$  cmp.w #5,d4                ; is it input from file?
    bgt.s 3$                   ; br if yes

    cmp.w #2,d4                ; input from CON:?
    bne.s 1$                   ; no must be some device.

    move.w #7,-(SP)
    trap #1
    addq.l #2,a7
    tst.w d0                   ; special key?
    bne.s 4$
    clr.w d0                   ; yes, convert key codes
    swap d0
    add.l #256,d0
    movem.l (a7)+,a1/d1-d4
    rts
4$  and.l #255,d0              ; no, mask off weird bits
    movem.l (a7)+,a1/d1-d4
    rts

1$  move.w d4,-(a7)            ; push device number
    move.w #2,-(a7)            ; push input code
    trap #13                   ; get character
    addq.l #4,a7               ; canx device and code
    and.l #255,d0
    movem.l (a7)+,a1/d1-d4
    rts

*   lea theChar,a0             ;  DEALING WITH A FILE HERE:

3$  dc.w $41fa,theChar-*-2     ; get input from spec'd file
    move.l a0,-(a7)            ; push address of place to put char
    move.l #1,-(a7)            ; reading one character
    move.w d4,-(a7)            ; push handle number
    move.w #$3F,-(a7)          ; push read command
    trap #1                    ; GEMDOS
    add.l #12,a7               ; fix the stack
    cmp.l #1,d0                ; did an error occur?
    bne.s 5$                   ; br if yes
    dc.w $41fa,theChar-*-2     ; otherwise, get address of character read
    clr.l d0
    move.b (a0),d0             ; get character
    movem.l (a7)+,a1/d1-d4
    rts                        ; and finished

5$  dc.w $41fa,vIn+8-*-2
    movem.l a0,-(a7)

    move.l (a0),d4             ; get file handle
    move.w d4,-(a7)            ; and close the file
    move.w #$3e,-(a7)
    trap #1
    addq.l #4,a7

    movem.l (a7)+,a0
    move.l #2,(a0)             ; set input device back to console
    clr.l d0                   ; return a 0 character
    movem.l (a7)+,a1/d1-d4
    rts

*
*    null    this word terminates the interpreter loop
*
   dc.b $c1
   dc.b 0
   dc.l 0      ; no more links to search

null bra doColon
   dc.l rFrom,drop,exit ; abort INTERPRET

*
*     :
*
   dc.b $81
   dc.b ':'
   dc.l null-6

colon    bra doColon
         dc.l spFetch,csp,store          ; set up csp for later stack checking
         dc.l create,smudge              ; create a smudged header
         dc.l here,four,minus,dp,store
         dc.l rbrac,exit                 ; set state to compiling

*
*     ;   terminates compilation of a dictionary defn
*
   dc.b $c1
   dc.b ';'
   dc.l colon-6

semicolon bra doColon
   dc.l qComp,qCsp  ; issue an error if the stack has been corrupted
   dc.l compile,exit,smudge,lbrac,exit

*
*     EXIT
*
   dc.b $c4
   dc.b 'EXIT',0  ; all names must have uneven length
   dc.l semicolon-6

doExit bra doColon
   dc.l state,fetch    ; are we compiling?
   dc.l zbranch,1$     ; br if no
   dc.l lit,exit,comma ; yes, compile exit.
   dc.l exit           ; and done!
1$ dc.l quit           ; immediate, so quit.

exit  move.l (a6)+,a5  ; restore ip from return stack
      move.l (a5)+,a3  ; fetch cfa pointed to by ip, and inc ip
      adda.l a4,a3
      jmp (a3)         ; go execute word
                       
*
*     .   ( n --- ) print the top value on the stack
*
   dc.b $81
   dc.b '.'
   dc.l doExit-10

dot bra doColon
   dc.l depth,zbranch,1$ ; if nothing on the stack, branch
   dc.l zero,dotR,exit   ; else print out the value
1$ dc.l adotqa
   dc.b 14
   dc.b ' Stack Empty',13,10
   EVEN
   dc.l exit

*
*     .R  ( n1 n2 --- ) output n1 right-justified in an n2 char field
*
   dc.b $82
   dc.b '.R',0
   dc.l dot-6

dotR bra doColon
   dc.l toR        ; hide field width
   dc.l dup,abs    ; leave a copy of n1, and abs n2 for conversion
   dc.l startSharp,sharpS,sign,endSharp  ; convert to string
   dc.l rFrom,over,minus,spaces,type,exit ; output spaces, then the string

*
*     U. ( u1 --- ) output unsigned number u1
*
   dc.b $82
   dc.b 'U.',0
   dc.l dotR-8

uDot bra doColon
   dc.l depth,zbranch,1$           ; if nothing on stack, say so
   dc.l startSharp,sharpS,endSharp ; convert to string
   dc.l type,exit                  ; and output it

1$ dc.l adotqa
   dc.b 14
   dc.b ' Stack empty',13,10
   EVEN
   dc.l exit

*
*     <">  ( --- addr n )
*
   dc.b $83
   dc.b "<"">"
   dc.l uDot-8

aquotea:
   moveq.l #0,d0
   move.b (a5)+,d0 ; get string length
   move.l a5,-(a7) ; push address of the string
   move.l d0,-(a7) ; push string length 
   adda.l d0,a5    ; point to just after the string

   move.l a5,d0    ; make sure a5 is even
   andi.l #1,d0
   beq.s 1$        ; br if even
   addq.l #1,a5    ; even out a5

1$ doNext

*
*     <.">  the actual code for ."
*
   dc.b $84
   dc.b "<."">",0
   dc.l aquotea-8

adotqa:
   clr.w d7
   move.b (a5)+,d7    ; get count of characters to print
   tst.w d7
   beq.s 3$           ; if count is zero, skip it
   bra.s 2$           ; start the loop

1$: clr.w d0
    move.b (a5)+,d0

    bsr charOut       ; print d0, a0 corrupted

2$: dbra d7,1$        ; branch if more
                       
    move.l a5,d0      ; make sure a5 is even
    andi.l #1,d0
    beq.s 3$          ; br if even

    addq.l #1,a5      ; even out a5

3$: doNext

*
*     <;CODE>
*
   dc.b $87
   dc.b '<;CODE>'
   dc.l adotqa-10

ascodea bra doColon
   dc.l rFrom,latest,pfa,cfa,store,exit

*
*     <+LOOP>     runtime procedure for +LOOP
*
   dc.b $87
   dc.b '<+LOOP>'
   dc.l ascodea-12

aplusLoopa move.l (a7)+,d0 ; inc value on return stack
   add.l d0,(a6)
   move.l 4(a6),d0    ; reached final value?
   cmp.l (a6),d0
   ble.s 1$           ; br if yes

   move.l (a5),a5     ; get value to branch to
   adda.l a4,a5       ; and go there
   doNext

1$ addq.l #8,a6       ; forget the loop parameters
   addq.l #4,a5       ; just inc past offset cell
   doNext             ; and continue

*
*     <ABORT>
*
   dc.b $87
   dc.b '<ABORT>'
   dc.l aplusLoopa-12

aaborta  bra doColon
   dc.l abort
   dc.l exit

*
*     <DO>   runtime procedure to initialize a loop
*
   dc.b $84
   dc.b '<DO>',0
   dc.l aaborta-12

adoa move.l (a7)+,d0
     move.l (a7)+,-(a6) ; move end number to stack
     move.l d0,-(a6)    ; move start number to return stack
     doNext

*
*     <FIND> ( addr1 addr2 --- addr3 b tf ) success
*            ( addr1 addr2 --- ff         ) unsuccess
*  begin a voc search at addr2 for string at addr1; addr3 is PFA, length b.

   dc.b $86
   dc.b '<FIND>',0
   dc.l adoa-10

afinda move.l (a7)+,a0 ; get beginning NFA
      move.l (a7)+,a1  ; get string to compare
      move.b (a1)+,d0  ; get length of compare string, and point a1 at text
      move.l a1,d4     ; save a1 for later
      move.l a0,d3
      moveq #0,d1

1$:   move.b (a0)+,d1  ; get length of current NFA
      andi.b #$3f,d1   ; strip off precedence bits
      bclr.b #5,d1     ; is smudge bit set?
      bne.s 4$         ; br if yes
      cmp.b d1,d0      ; length same as compare?
      bne.s 4$         ; no, bump to next NFA

      move.l a0,d3
      moveq #0,d2
      move.b d1,d2     ; get # of bytes to compare
      bra.s 3$         ; start comparison

2$:   cmpm.b (a0)+,(a1)+ ; compare string to NFA
      bne.s 6$         ; no match, skip it.

3$:   dbra d2,2$

      move.l d3,a0
      subq.l #1,a0     ; point to length byte
      move.b (a0)+,d1  ; get it with precedence & smudge intact
      move.l d1,d2     ; and save it for later
      andi.l #$3f,d1   ; strip off crufty bits

      add.l a0,d1      ; point to LFA
      move.l d1,a0
      andi.l #1,d1
      beq 7$
      addq.l #1,a0     ; and adjust for evenness if neccessary
7$:   addq.l #8,a0     ; point to PFA

      move.l a0,-(a7)  ; and put PFA on stack
      move.l d2,-(a7)  ; length on stack
      move.l #1,-(a7)  ; put a true flag on the stack
      doNext           ; and escape!

6$:   move.l d3,a0     ; get NFA back
      move.l d4,a1     ; restore address of comparison string

4$:   add.l a0,d1      ; scan past text of NFA
      move.l d1,a0
      andi.l #1,d1     ; is d1 even?
      beq.s 5$         ; br if yes
      addq.l #1,a0     ; else add 1 to pointer

5$:   move.l (a0),a0   ; bump to next NFA
      adda.l a4,a0     ; adjust for absolute offset
      cmpa.l a4,a0     ; if a0=a4 then a0 must have been 0, ie:last link
      bne.s 1$         ; br if not last link, else report "Sorry..."

      clr.l -(a7)      ; clear the word on the stack to signal false
      doNext

*
*     <LOOP>
*
   dc.b $86
   dc.b '<LOOP>',0
   dc.l afinda-12

aloopa addq.l #1,(a6) ; inc value on return stack
   move.l 4(a6),d0    ; reached final value?
   cmp.l (a6),d0
   ble.s 1$           ; br if yes

   move.l (a5),a5     ; get value to branch to
   adda.l a4,a5       ; and go there
   doNext

1$ addq.l #8,a6       ; forget the loop parameters
   addq.l #4,a5       ; just inc past offset cell
   doNext             ; and continue

*
*     <NUMBER>  ( n1 addr1 --- n2 addr2 ) n1 is an accumulator
*                 addr1 is address of string to convert, n2 is result
*                  addr2 is address of first non-converted char
   dc.b $88
   dc.b '<NUMBER>',0
   dc.l aloopa-12

aNumbera bra doColon
1$: dc.l onePlus,dup,toR,cFetch,base,fetch,digit,zbranch
    dc.l 2$
    dc.l doSwap,base,fetch,unsTimes,plus,rFrom,branch
    dc.l 1$
2$: dc.l rFrom,exit

*
*     <VAR>
*
   dc.b $85
   dc.b '<VAR>'
   dc.l aNumbera-14

aVara move.l a5,-(a7) ; get next address from return stack
   jmp exit           ; and set for use.

*
*     ABORT
*
   dc.b $85
   dc.b 'ABORT'
   dc.l aVara-10

abort bra doColon
   dc.l spStore   ; reset parm stack
   dc.l quit
*  dc.l exit

*
*     COLD
*
   dc.b $84
   dc.b 'COLD',0
   dc.l abort-10

cold  bra doColon
      dc.l coldStuff ; do all the neat power up stuff
      dc.l clrPage   ; clear screen
      dc.l adotqa    ; write the following message
      dc.b 53
      dc.b 'FUSION FORTH 1.00',13,10
      dc.b 'by Nick Porcino and Don Palmer'
      dc.b 27,'e'    ; make cursor visible
      dc.b 27,'v'    ; wrap around
      EVEN
      dc.l cr        ; do a carriage return
      dc.l aaborta   ; start the command line stuff
      dc.l exit      ; end of definition

*
*  COLDSTUFF  does all the necessary power up stuff
*
   dc.b $89
   dc.b 'COLDSTUFF'
   dc.l cold-10

coldStuff bra doColon
      dc.l hidemouse          ; prevent little green spots
      dc.l ainit,aptr,store   ; initialize lineA graphics
      dc.l getRez,startRez,store ; make sure FORTH knows about resolution
      dc.l two,lToW,one,xbios,setlog ; set screenbase
      dc.l one,setColor       ; set color for graphics

      dc.l zero,vmark,store   ; clear text buffer
      dc.l two,vOut1,store    ; set _OUT1 to CON:
      dc.l lit,-1,vOut2,store ; set _OUT2 to NULL:
      dc.l two,vIn,store      ; set _IN to CON:
      dc.l zero,toIn,store    ; clear input stream offset
      dc.l zero,state,store   ; set to non-compiling
      dc.l spStore            ; init SP, ie: A7
      dc.l decimal            ; set base to decimal
      dc.l exit

*
*     ! ( n addr --- ) stores 32 bit n into (addr)
*
   dc.b $81
   dc.b '!'
   dc.l coldStuff-14

store move.l (a7)+,a0   ; get address off stack
      move.l (a7)+,(a0) ; and store value
      doNext           ; and done

*
*     @  ( addr --- n ) fetch a 32 bit n from (addr)
*
   dc.b $81
   dc.b '@'
   dc.l store-6

fetch   move.l (a7)+,a0
   move.l (a0),-(a7)
   doNext

*
*     '  ( --- addr ) ' <name> returns address of <name>
*
   dc.b $c1
   dc.b ''''
   dc.l fetch-6

tick bra doColon
   dc.l dashFind,zbranch,2$         ; branch if <name> not found
   dc.l doSwap,lit,4,minus,doSwap   ; adjust PFA to be CFA
   dc.l state,fetch,zbranch,1$      ; branch if not compiling
   dc.l lit,lit,comma,drop,comma    ; compile addr of <name> as literal
   dc.l exit

1$ dc.l drop,exit ; throw away length word, return addr

2$ dc.l error,exit
*
*     <#  begin conversion of an unsigned number into a text string
*
   dc.b $82
   dc.b '<#',0
   dc.l tick-6

startSharp bra doColon
   dc.l pad,hld,store,exit

*
*    SIGN ( n u1 --- u1 ) if n is negative insert a "-" into the string
*
   dc.b $84
   dc.b 'SIGN',0
   dc.l startSharp-8

sign bra doColon
   dc.l doSwap,zerolt,zbranch,1$
   dc.l lit,45,hold
1$ dc.l exit

*
*
*     # ( u1 -- u2 ) generate next digit in output text string.
*                    u1 is div'd by current base, leaving quotient u2
*                    for further processing.
   dc.b $81
   dc.b '#'
   dc.l sign-10

sharp bra doColon
   dc.l base,fetch,uDivMod,doSwap,dup    ; get remainder
   dc.l lit,9,grtrThan,zbranch,1$      ; if remainder >9 add 7 to rem
   dc.l lit,7,plus
1$ dc.l lit,48,plus,hold           ; convert to ASCII and hold
   dc.l exit

*
*     #S  ( u1 -- 0 ) generate ASCII chars until done.
*
   dc.b $82
   dc.b '#S',0
   dc.l sharp-6

sharpS bra doColon
1$ dc.l sharp,dup,zeroEq,zbranch,1$,exit

*
*     #>  ( u1 --- addr n ) end conversion of number into string.
*             addr points to string, n reports its length.
   dc.b $82
   dc.b '#>',0
   dc.l sharpS-8

endSharp bra doColon
   dc.l drop,hld,fetch,pad,over,minus,exit

*
*     HOLD ( c -- ) insert char c into the text string
*
   dc.b $84
   dc.b 'HOLD',0
   dc.l endSharp-8

hold bra doColon
   dc.l one,hld,minusStore     ; dec ptr to next char locn
   dc.l hld,fetch,cStore,exit  ; store character c

*
*     PAD ( -- addr ) leaves a ptr to start of text buffer
*
   dc.b $83
   dc.b 'PAD'
   dc.l hold-10

pad bra doColon
   dc.l here,lit,80,plus,exit

*
*     HLD ( --- addr ) leaves ptr to text buffer pointer
*
   dc.b $83
   dc.b 'HLD'
   dc.l pad-8

hld dc.l textGunk+$41ec0000 ; get address of HLD
* lea textGunk(a4),a0
   move.l a0,-(a7)          ; push address on stack
   doNext

*
*     ,  ( n --- )  stores n at HERE, then increments HERE by 4
*
   dc.b $81
   dc.b ','
   dc.l hld-8

comma dc.l nextFree+$41ec0000  ; get address of DP
*  lea nextFree(a4),a0
   move.l (a0),a1              ; get HERE
   move.l (a7)+,(a1)+          ; store n at HERE, inc HERE
   move.l a1,(a0)              ; save HERE at DP
   doNext

*
*     +   ( n1 n2 --- n1+n2 )
*
   dc.b $81
   dc.b '+'
   dc.l comma-6

plus   move.l (a7)+,d0
   add.l d0,(a7)
   doNext

*
*     +!  ( n addr --- ) inc addr by n
*
   dc.b $82
   dc.b '+!',0
   dc.l plus-6

plusStore move.l (a7)+,a0 ; get addr
         move.l (a7)+,d0  ; get n
         add.l d0,(a0)    ; inc addr
         doNext

*
*     -!  ( n addr --- ) dec addr by n
*
   dc.b $82
   dc.b '-!',0
   dc.l plusStore-8

minusStore move.l (a7)+,a0 ; get addr
   move.l (a7)+,d0         ; get n
   sub.l d0,(a0)           ; dec addr
   doNext

*
*     +LOOP ( n --- ) incr value on return stack by n and loop
*
   dc.b $c5
   dc.b '+LOOP'
   dc.l minusStore-8

plusLoop bra doColon
   dc.l compile,aplusLoopa,backResolve,exit

*
*     -   ( n1 n2 --- n1-n2 )
*
   dc.b $81
   dc.b '-'
   dc.l plusLoop-10

minus   move.l (a7)+,d0
   sub.l d0,(a7)
   doNext

*
*     -FIND   ( --- addr b tf )  found
*             ( --- ff        ) not found
*  copy the next bl delimited word to word buff with preceeding length byte
*  If match found leave word's pfa and length byte below true flag,
*   else, leave a false flag and nothing else.
   dc.b $85
   dc.b '-FIND'
   dc.l minus-6

dashFind bra doColon
   dc.l bl,word  ; copy next bl delimited word from text stream
   dc.l here     ; get next available spot
   dc.l latest   ; get nfa of most recent addition to library
   dc.l afinda   ; search vocabulary
   dc.l exit

*
*     *   ( n n --- n*n )   16 bits x 16 bits >>> 32 bits
*
   dc.b $81
   dc.b '*'
   dc.l dashFind-10

times   move.l (a7)+,d0
   move.l (a7),d1
   move.b #0,d3
   move.b d3,d4
   tst.l d0
   smi d3
   bpl.s 1$
   neg.l d0
1$ tst.l d1
   smi d4
   bpl.s 2$
   neg.l d1
2$ eor.b d3,d4

   cmp.l d0,d1
   bge.s 3$
   exg.l d0,d1
3$ move.l d1,d2
   swap d1
   clr.w d1
   swap d1
   mulu d0,d1
   clr.w d2
   swap d2
   mulu d0,d2
   swap d2
   add.l d2,d1
   tst.b d4
   beq.s 4$
   neg.l d1
4$ move.l d1,(a7)
   doNext

*
*  F*  ( n1 n2 --- n3 )
*
   dc.b $82
   dc.b 'F*',0
   dc.l times-6

ftimes move.l (a7)+,d0
   move.l (a7),d1
   move.b #0,d5          ; d0 = low word 1
   move.b d3,d6          ; d1 = low word 2
   tst.l d0              ; d2 = high word 1
   smi d5                ; d3 = high word 2
   bpl.s 1$              ; d4 = accumulator
   neg.l d0
1$ tst.l d1
   smi d6
   bpl.s 2$
   neg.l d1
2$ eor.b d5,d6

   move.l d0,d2
   move.l d1,d3

   swap d0
   clr.w d0
   swap d0

   swap d1
   clr.w d1
   swap d1

   clr.w d2
   swap  d2
   clr.w d3
   swap d3
   clr.w d4
   swap  d4

   move.w d0,d4
   mulu d1,d4
   clr.w d4
   swap  d4

   mulu d3,d0
   add.l d0,d4

   mulu d2,d1
   add.l d1,d4

   mulu d2,d3
   swap d3
   clr.w d3
   add.l d3,d4

   tst.b d6
   beq.s 4$
   neg.l d4
4$ move.l d4,(a7)
   doNext

fts:                     ; multiplies d0,d1
   move.b #0,d5          ; d0 = low word 1
   move.b d3,d6          ; d1 = low word 2
   tst.l d0              ; d2 = high word 1
   smi d5                ; d3 = high word 2
   bpl.s 1$              ; d4 = accumulator
   neg.l d0
1$ tst.l d1
   smi d6
   bpl.s 2$
   neg.l d1
2$ eor.b d5,d6

   move.l d0,d2
   move.l d1,d3

   swap d0
   clr.w d0
   swap d0

   swap d1
   clr.w d1
   swap d1

   clr.w d2
   swap  d2
   clr.w d3
   swap d3
   clr.w d4
   swap  d4

   move.w d0,d4
   mulu d1,d4
   clr.w d4
   swap  d4

   mulu d3,d0
   add.l d0,d4

   mulu d2,d1
   add.l d1,d4

   mulu d2,d3
   swap d3
   clr.w d3
   add.l d3,d4

   tst.b d6
   beq.s 4$
   neg.l d4
4$ rts

*
* JULIA ( x y addr --- cnt ) A fractal word.
*
   dc.b $85
   dc.b 'JULIA'
   dc.l ftimes-8

julia move.l (a7)+,a0 ; get parameter block address
   move.l #0,a1      ; initialize count

1$ move.l (a7),d0    ; get imag
   move.l d0,d1
   bsr   fts         ; imag^2
   move.l d4,a2      ; save imag^2

   move.l 4(a7),d0   ; get real
   move.l d0,d1
   bsr   fts         ; real^2

   move.l a2,d1      ; calc real^2+imag^2
   add.l d4,d1
   cmpi.l #262144,d1 ; is > 4.0?
   bgt.s 99$         ; yes, finished.

   sub.l a2,d4       ; real^2-imag^2
   sub.l 4(a0),d4    ; -tx
   move.l d4,a2      ; save new real part

   move.l (a7),d0    ; get imag
   move.l 4(a7),d1   ; get real
   bsr   fts         ; get real*imag
   add.l d4,d4       ; *2

   sub.l 8(a0),d4    ; subtract _ty
   move.l d4,(a7)    ; store it

   move.l a2,4(a7)   ; store it

   addq.l #1,a1      ; increase the count
   cmp.l (a0),a1     ; is count still under max?
   blt.s 1$

99$ addq.l #4,a7     ; destroy one item from the stack
   move.l a1,(a7)    ; store the count
   doNext            ; and exit

*
* MANDL ( x y addr --- cnt ) A fractal word.
*
   dc.b $85
   dc.b 'MANDL'
   dc.l julia-10

mandl move.l (a7)+,a0   ; get parameter block address
   move.l #0,a1         ; initialize count

   clr.l 4(a0)
   clr.l 8(a0)          ; initialize z

1$ move.l 8(a0),d0      ; get imag
   move.l d0,d1     
   bsr   fts            ; imag^2
   move.l d4,a2         ; save imag^2
    move.l 4(a0),d0     ; get real
    move.l d0,d1
    bsr   fts           ; real^2
     move.l a2,d2       ; calc real^2+imag^2
     add.l d4,d2
     cmpi.l #262144,d2  ; is > 4.0?
     bgt.s 99$          ; yes, finished.
      sub.l a2,d4       ; real^2-imag^2
      move.l 4(a7),d0   ; get real
      add.l d0,d4
      move.l 4(a0),d0   ; get previous real
      move.l d4,4(a0)   ; save new real      xxx
       move.l 8(a0),d1  ; get old imag
       bsr   fts        ; real*imag
       add.l d4,d4      ; *2
       move.l (a7),d0   ; get cimag
       add.l d4,d0      ; real*imag+cimag
       move.l d0,8(a0)  ; save new imag
        addq.l #1,a1    ; increase the count
        cmp.l (a0),a1   ; is count still under max?
        blt.s 1$

99$ addq.l #4,a7     ; destroy one item from the stack
   move.l a1,(a7)    ; store the count
   doNext            ; and exit

*
*     U*     ( u1 u2 --- u3 ) multiplies two unsigned numbers together
*
   dc.b $82
   dc.b 'U*',0
   dc.l mandl-10

unsTimes move.l (a7)+,d0
   move.l (a7),d1
   cmp.l d0,d1
   bge.s 1$
   exg.l d0,d1

1$ move.l d1,d2
   swap d1
   clr.w d1
   swap d1
   mulu d0,d1
   clr.w d2
   swap d2
   mulu d0,d2
   swap d2
   add.l d2,d1
   move.l d1,(a7)
   doNext

*
*     /  ( n1 n2 --- n1/n2 )    32 bits / 16 bits >>> 16 bits
*
   dc.b $81
   dc.b '/'
   dc.l unsTimes-8

divide move.l (a7)+,d2
   move.l (a7)+,d1
   bsr divStuff
   move.l d1,-(a7)
   doNext

*
*   U/ ( u1 u2 -- u-quot )
*
   dc.b $82
   dc.b 'U/',0
   dc.l divide-6

uDivide move.l (a7)+,d2
   move.l (a7)+,d1
   bsr uDivStuff
   move.l d1,-(a7)
   doNext

*
*   U/MOD   ( u1 u2 -- u-rem u-quot )
*
   dc.b $85
   dc.b 'U/MOD'
   dc.l uDivide-8

uDivMod move.l (a7)+,d2
   move.l (a7)+,d1
   bsr uDivStuff
   move.l d2,-(a7)
   move.l d1,-(a7)
   doNext

*
*    /MOD  ( n1 n2 --- rem quot )
*
   dc.b $84
   dc.b '/MOD',0
   dc.l uDivMod-10

divMod move.l (a7)+,d2
      move.l (a7)+,d1
      bsr divStuff
      move.l d2,-(a7)
      move.l d1,-(a7)
      doNext

divStuff tst.l d2  ; is divisor >0?
   bpl.s 1$        ; if yes, go on to next bit
   neg.l d2        ; otherwise, negate it,
   bsr 1$          ; do the division,
   neg.l d1        ; negate it again,
   rts             ; and exit

1$ tst.l d1        ; is dividend >0?
   bpl.s uDivStuff ; if yes, go on to next bit
   neg.l d1        ; otherwise, negate it,
   bsr uDivStuff   ; do the division,
   neg.l d1        ; negate the results
   neg.l d2
   rts             ; and exit

uDivStuff cmp.l #$ffff,d2 ; is divisor a word?
   bls wordDiv     ; br if yes
   cmp.l d1,d2     ; does divisor=dividend?
   beq 1$          ; yes, don't bother dividing anything
   bls 2$          ; is dividend<divisor?
   move.l d1,d2    ; yes, make remainder = dividend
   moveq.l #0,d1   ; and quotient = 0
   rts

1$ moveq.l #0,d2   ; make remainder 0
   moveq.l #1,d1   ; and quotient 1
   rts             ; exit

2$ movem.l d3-d5,-(a7)
   move.l d2,d3
   clr.w d3
   swap d3
   addq.l #1,d3
   move.l d1,d4
   move.l d2,d5
   move.l d3,d2
   bsr wordDiv
   move.l d5,d2
   divu d3,d2
   divu d2,d1
   swap d1
   clr.w d1
   swap d1

3$ move.l d5,d2
   move.l d5,d3
   swap d3
   mulu d1,d2
   mulu d1,d3
   swap d3
   add.l d3,d2
   sub.l d4,d2
   bhi.s 4$
   neg.l d2
   cmp.l d2,d5
   bhi.s 5$
   addq.l #1,d1
4$ subq.l #1,d1
   bra.s 3$

5$ movem.l (a7)+,d3-d5
   rts

wordDiv movem.w d1/d3,-(a7)
   clr.w d1
   swap d1
   divu d2,d1
   move.w d1,d3
   move.w (a7)+,d1
   divu d2,d1
   swap d1
   moveq.l #0,d2
   move.w d1,d2
   move.w d3,d1
   swap d1
   move.w (a7)+,d3
   rts

*
*     MOD   ( n1 n2 --- n1-(n1/n2)*n2 ) returns mod of n1 n2
*
   dc.b $83
   dc.b 'MOD'
   dc.l divMod-10

mod move.l (a7)+,d2
   move.l (a7)+,d1
   bsr divStuff
   move.l d2,-(a7)
   doNext

*
*     [  suspend compilation
*
   dc.b $c1
   dc.b '['
   dc.l mod-8

lbrac bra doColon
   dc.l lit,0,state,store,exit

*
*     ]  restart compilation
*
   dc.b $c1
   dc.b ']'
   dc.l lbrac-6

rbrac bra doColon
   dc.l lit,192,state,store,exit

*
*     0  ( --- 0 )
*

   dc.b $81
   dc.b '0'
   dc.l rbrac-6

zero   clr.l -(a7)
   doNext

*
*      0! ( addr -- )
*
   dc.b $82
   dc.b '0!',0
   dc.l zero-6

zeroStore move.l (a7)+,a0
  clr.l (a0)
  doNext

*
*      0=  ( n --- f )
*
   dc.b $82
   dc.b '0=',0
   dc.l zeroStore-8

zeroEq   tst.l (a7)
   seq d0
   andi.l #1,d0
   move.l d0,(a7)
   doNext

*
*     0<  ( n --- f )
*
   dc.b $82
   dc.b '0<',0
   dc.l zeroEq-8

zerolt   tst.l (a7)
   slt d0
   andi.l #1,d0
   move.l d0,(a7)
   doNext

*
*     0>  ( n --- f )
*
   dc.b $82
   dc.b '0>',0
   dc.l zerolt-8

zerogt   tst.l (a7)
   sgt d0    ; fill byte with flag
   andi.l #1,d0
   move.l d0,(a7)
   doNext

*
*     0BRANCH
*
   dc.b $87
   dc.b '0BRANCH'
   dc.l zerogt-8

zbranch move.l (a7)+,d0 ; get the top value off the stack
   bne.s 1$             ; if value was 0, false, then branch spec'd offset
   move.l (a5),a5       ; get value to branch to
   adda.l a4,a5
   doNext

1$: addq.l #4,a5        ; else for true, just inc past offset cell
   doNext

*
*      1  ( --- 1 )
*
   dc.b $81
   dc.b '1'
   dc.l zbranch-12

one   moveq.l #1,d0
   move.l d0,-(a7)
   doNext

*
*     1+  ( n --- n+1 )
*
   dc.b $82
   dc.b '1+',0
   dc.l one-6

onePlus   addq.l #1,(a7)
   doNext

*
*     1-  ( n --- n-1 )
*
   dc.b $82
   dc.b '1-',0
   dc.l onePlus-8

oneMinus  subq.l #1,(a7)
   doNext

*
*     2   ( --- 2 )
*         
   dc.b $81
   dc.b '2'
   dc.l oneMinus-8

two   moveq.l #2,d0
   move.l d0,-(a7)
   doNext

*
*     2+   ( n --- n+2 )
*
   dc.b $82
   dc.b '2+',0
   dc.l two-6

twoPlus   addq.l #2,(a7)
   doNext

*
*     2-     ( n --- n-2 )
*
   dc.b $82
   dc.b '2-',0
   dc.l twoPlus-8

twoMinus   subq.l #2,(a7)
   doNext

*
*     2*  ( n --- n*2 )
*
   dc.b $82
   dc.b '2*',0
   dc.l twoMinus-8

twoTimes   move.l (a7),d0
   add.l d0,(a7)
   doNext

*
*     2/  ( n --- n/2 )
*
   dc.b $82
   dc.b '2/',0
   dc.l twoTimes-8

twoDiv move.l (a7)+,d0
   asr.l #1,d0
   move.l d0,-(a7)
   doNext

*
*     3 ( -- 3 )
*
   dc.b $81
   dc.b '3'
   dc.l twoDiv-8

three moveq.l #3,d0
   move.l d0,-(a7)
   doNext

*
*     4  ( -- 4 )
*
   dc.b $81
   dc.b '4'
   dc.l three-6

four moveq.l #4,d0
   move.l d0,-(a7)
   doNext

*
*     4+  ( n -- n+4 )
*
   dc.b $82
   dc.b '4+',0
   dc.l four-6

fourPlus addq.l #4,(a7)
   doNext

*
*     4-   ( n --- n-4 )
*
   dc.b $82
   dc.b '4-',0
   dc.l fourPlus-8

fourMinus subq.l #4,(a7)
   doNext

*
*     4*   ( n --- n*4 )
*
   dc.b $82
   dc.b '4*',0
   dc.l fourMinus-8

fourTimes move.l (a7),d0
   add.l d0,d0
   add.l d0,d0
   move.l d0,(a7)
   doNext

*
*     4/   ( n --- n/4 )
*
   dc.b $82
   dc.b '4/',0
   dc.l fourTimes-8

fourDiv move.l (a7),d0
      asr.l #2,d0
      move.l d0,(a7)
      doNext
*
*    5   ( -- 5 )
*
   dc.b $81,'5'
   dc.l fourDiv-8
five moveq.l #5,d0
   move.l d0,-(a7)
   doNext
*     6 ( -- 6 )
   dc.b $81,'6'
   dc.l five-6
six moveq.l #6,d0
   move.l d0,-(a7)
   doNext
*     7 ( -- 7 )
   dc.b $81,'7'
   dc.l six-6
seven moveq.l #7,d0
   move.l d0,-(a7)
   doNext
*     8 ( -- 8 )
   dc.b $81,'8'
   dc.l seven-6
eight moveq.l #8,d0
   move.l d0,-(a7)
   doNext
*     9 ( -- 9 )
   dc.b $81,'9'
   dc.l eight-6
nine moveq.l #9,d0
   move.l d0,-(a7)
   doNext

*
*    >IN   ( --- addr ) returns pointer to offset into input stream
*
   dc.b $83
   dc.b '>IN'
   dc.l nine-6

toIn  dc.l inOffset+$41ec0000
*  lea inOffset(a4),a0
   move.l a0,-(a7)
   doNext

*
*     >MARK   ( --- addr ) addr is where >RESOLVE will store it's branch
*
   dc.b $85
   dc.b '>MARK'
   dc.l toIn-8

toMark bra doColon
   dc.l here,lit,4,allot,exit

*
*     >RESOLVE  resolves marked branches
*
   dc.b $88
   dc.b '>RESOLVE',0
   dc.l toMark-10

toResolve bra doColon
   dc.l here,org,minus,doSwap,store,exit

*
*     <MARK  mark a backwards branch
*
   dc.b $85
   dc.b '<MARK'
   dc.l toResolve-14

backMark bra doColon
   dc.l here,org,minus,exit

*
*     <RESOLVE finish up the backwards branch
*
   dc.b $88
   dc.b '<RESOLVE',0
   dc.l backMark-10

backResolve bra doColon
   dc.l comma,exit

*
*     >R   ( n -- ) store on return stack
*
   dc.b $82
   dc.b '>R',0
   dc.l backResolve-14

toR   move.l (a7)+,-(a6)
   doNext

*
*     R>   ( --- n ) value from return stack onto parm stack
*
   dc.b $82
   dc.b 'R>',0
   dc.l toR-8

rFrom   move.l (a6)+,-(a7)
   doNext

*
*      =    ( n1 n2 --- f )
*
   dc.b $81
   dc.b '='
   dc.l rFrom-8

equal   move.l (a7)+,d0 ; get n2
   cmp.l  (a7),d0  ; = n1 ?
   beq.s setTrue
   clr.l (a7)
   doNext

*
*      <   ( n1 n2 --- f )
*
   dc.b $81
   dc.b '<'
   dc.l equal-6

lessThan
 move.l (a7)+,d0
 cmp.l (a7),d0
 bgt.s setTrue
 clr.l (a7)
 doNext
setTrue: moveq.l #1,d0
 move.l d0,(a7)
 doNext

*
*      <>   ( n1 n2 --- f )
*
   dc.b $82
   dc.b '<>',0
   dc.l lessThan-6

notEqual move.l (a7)+,d0 ; get n2
   cmp.l (a7),d0 ; compare to n1
   bne.s setTrue ; set flag
   clr.l (a7)
   doNext

*
*       >   ( n1 n2 --- f )
*
   dc.b $81
   dc.b '>'
   dc.l notEqual-8

grtrThan   move.l (a7)+,d0 ; get n2
   cmp.l (a7),d0   ; compare to n1
   blt.s setTrue   ; set flag
   clr.l (a7)
   doNext

*
*     ?COMP  issue an error if not compiling
*
   dc.b $85
   dc.b '?COMP'
   dc.l grtrThan-6

qComp bra doColon
   dc.l state,fetch,zeroEq,one,qError,exit

*
*     ?CSP   issue an error if stack isn't empty
*
   dc.b $84
   dc.b '?CSP',0
   dc.l qComp-10

qCsp bra doColon
   dc.l spFetch,csp,fetch,minus,zero,qError,exit

*
*     ?ERROR ( f n --- ) if f true, do error message number n
*
   dc.b $86
   dc.b '?ERROR',0
   dc.l qCsp-10

qError bra doColon
   dc.l doSwap,zbranch,1$                        ; if no error, exit
   dc.l cr,lit,24,times,lit,errors,org,plus,plus ; calc offset into error table
   dc.l lit,24,type,spStore,error,exit           ; type error message and abort
1$ dc.l drop,exit

errors:
   dc.b 'Stack not empty         ' ; 0
   dc.b 'Not in compilation mode ' ; 1
   dc.b 'Not in immediate mode   ' ; 2
   dc.b 'Stack has underflowed - ' ; 3
   dc.b 'Cannot redefine NULL    ' ; 4
   dc.b 'Word not found --       ' ; 5
   dc.b 'Stack has overflowed -- ' ; 6
   dc.b 'In protected dictionary:' ; 7

   EVEN

*
*     ?EXEC  issues an error if not in immediate mode
*
   dc.b $85
   dc.b '?EXEC'
   dc.l qError-12

qExec bra doColon
   dc.l state,fetch,two,qError,exit

*
*     ?STACK  issues an error if the stack has underflowed
*
   dc.b $86
   dc.b '?STACK',0
   dc.l qExec-10

qStack bra doColon
   dc.l spFetch,sZero,fetch,grtrThan,three,qError
   dc.l depth,lit,256,grtrThan,six,qError,exit

*
*     ABS   ( n --- abs(n) )
*
   dc.b $83
   dc.b 'ABS'
   dc.l qStack-12

abs tst.l (a7) ; n negative?
    bge 1$     ; br if yes
    neg.l (a7) ; else negate
1$: doNext

*
*     ALLOT ( n --- )  bumps HERE by n
*
   dc.b $85
   dc.b 'ALLOT'
   dc.l abs-8

allot bra doColon
   dc.l dp,plusStore,exit

*
*     AND   ( n1 n2 --- result )
*
   dc.b $83
   dc.b 'AND'
   dc.l allot-10

doAnd   move.l (a7)+,d0
   and.l d0,(a7)
   doNext

*
*     BACK  ( addr - ) calc offset from top of dict'ry to addr, and
*                        and compile it.
   dc.b $84
   dc.b 'BACK',0
   dc.l doAnd-8

back bra doColon
   dc.l here,minus,comma,exit

*
*     BASE  ( --- numBase )
*
   dc.b $84
   dc.b 'BASE',0
   dc.l back-10

base  dc.l numBase+$41ec0000
*  lea numBase(a4),a0
   move.l a0,-(a7)
   doNext

*
*     BIOS ( params # of words --- result )
*
   dc.b $84
   dc.b 'BIOS',0
   dc.l base-10

bios move.l (a7)+,d7 ; get # of params
     add.l d7,d7     ; *2=bytes
     trap #13        ; call bios
     add.l d7,a7     ; fix stack
     move.l d0,-(a7) ; return a result
     doNext

*
*     BUFFER ( --- addr ) returns the address of the big buffer
*
   dc.b $86
   dc.b 'BUFFER',0
   dc.l bios-10

buffer dc.l $41ec0000+bigBuff
*  lea bigBuff(a4),a0   ; get address of big buffer onto parm stack
   move.l (a0),-(a7)    
   doNext

*
*     BL ( --- $20 )
*
   dc.b $82
   dc.b 'BL',0
   dc.l buffer-12

bl   move.l #$20,-(a7)
   doNext

*
*     BLANKS ( addr n --- ) fill addr with n blanks
*
   dc.b $86
   dc.b 'BLANKS',0
   dc.l bl-8

blanks bra doColon
   dc.l bl,fill,exit

   include "d:cf2.s"
   include "d:fx.s"

forthEnd dc.l 0

    end



