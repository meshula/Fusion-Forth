

********************************************************************
*   forth extensions                                               *
********************************************************************

*
*     OPEN  ( string -- handle/errorCode )  typical use: " TEST.BLK" OPEN
*
   dc.b $84
   dc.b 'OPEN',0
   dc.l doXor-8

open bra doColon
   dc.l sToCs,toR,two,lToW,rFrom,lit,61,lToW,four,gemdos,exit

*
*     CLOSE ( handle -- errorCode )
*
   dc.b $85
   dc.b 'CLOSE'
   dc.l open-10

close
   addq.l #2,a7     ; change handle to a word
   move.w #62,-(a7) ; command on stack
   trap #1          ; close file
   move.l d0,(a7)   ; save error code, maintain stack framing
   doNext

*
*  C/L  ( -- addr )
*
   dc.b $83
   dc.b 'C/L'
   dc.l close-10

cperl bra doColon
   dc.l aVara,64

*
*     _MARK ( --- addr ) variable holding start address of text workspace
*
   dc.b $85
   dc.b '_MARK'
   dc.l cperl-8

vmark bra doColon
   dc.l aVara,0

*
*     _TOTAL ( --- addr ) variable holding end of text workspace
*
   dc.b $86
   dc.b '_TOTAL',0
   dc.l vmark-10

vtotal bra doColon
   dc.l aVara,0


propout:
   cmp.w #$d,d0      ; is character CR?
   bne.s 2$
   dc.w $41fa,pdata-*-2
   clr.w (a0)        ; yes, reset x
   rts

2$ cmp.w #$a,d0      ; is character line feed?
   bne.s 3$
   dc.w $41fa,pdata-*-2
   move.w 2(a0),d0   ; yes, get old y
   add.w  6(a0),d0   ; add lead
   move.l 8(a0),a1   ; get address of font
   add.w (a1),d0     ; add height of font

   dc.w $43fa,_rez-2-*
   tst.l (a1)        ; get screen resolution
   bne.s 4$          ; branch if color

   cmp.w #400,d0
   bgt.s 6$
   bra.s 5$

4$ cmp.w #200,d0
   blt.s 5$
6$ clr.w d0          ; wrap y to the top

5$ move.w d0,2(a0)   ; save new y
   rts

3$ swap d0
   clr.w d0
   swap d0
   move.l d0,-(a7)   ; save character to print
   dc.w $41fa,_rez-2-*
   move.l (a0),d4    ; get screen resolution

   dc.w $41fa,_scrnbase-2-*
   move.l (a0),a1    ; get screen base address

   dc.w $41fa,pdata-*-2
   move.w 2(a0),d0   ; get y

   cmp.b #2,d4       ; is it monochrome?
   beq   ph          ; branch if yes

   move.w 14(a0),d5  ; get character color
   mulu  #160,d0     ; calc address offset

   adda.l d0,a1      ; calc absolute screen address

   clr.w d1
   swap d1
   move.w (a0),d0    ; get x coordinate
   move.w d0,d1

   dbra d4,pm        ; branch if it's medium rez

   lsr.w #1,d1
   and.w #$f8,d1     ; calc pixel group
   adda.l d1,a1      ; get screen address

   and.w #$f,d0      ; get pixel within group

   move.l 8(a0),a2   ; get address of font
   clr.w d3
   swap  d3
   move.w (a2),d3    ; get number of lines in font
   move.l (a7),d1    ; get character to output
   move.l d3,d4
   add.w d4,d4
   mulu d4,d1        ; times bytes per character
   add.w #130,d1     ; font data starts 130 bytes in
   add.l d1,a2       ; get address of character
   subq.w #1,d3      ; dec line count

1$ clr.w d1
   swap d1
   move.w (a2)+,d1   ; get first line of character
   ror.l d0,d1       ; shift it appropriately
   move.w d1,d2
   or.w (a1),d1      ; mask the data in
   move.w d1,(a1)+   ; write the data out plane0

   move.w d2,d1
   or.w (a1),d1
   move.w d1,(a1)+   ; plane 1

   move.w d2,d1
   or.w (a1),d1
   move.w d1,(a1)+   ; plane 2

   move.w d2,d1
   or.w (a1),d1
   move.w d1,(a1)+   ; plane 3

   swap d1
   move.w d1,d2
   or.w (a1),d1
   move.w d1,(a1)+
   move.w d2,d1
   or.w (a1),d1
   move.w d1,(a1)+
   move.w d2,d1
   or.w (a1),d1
   move.w d1,(a1)+
   move.w d2,d1
   or.w (a1),d1
   move.w d1,(a1)

   adda.l #146,a1

   dbra d3,1$        ; repeat for all lines
   bra pem

pm lsr.w #2,d1
   and.w #$fc,d1     ; calc pixel group
   adda.l d1,a1      ; get screen address

   and.w #$f,d0      ; get pixel within group

   move.l 8(a0),a2   ; get address of font
   clr.w d3
   swap  d3
   move.w (a2),d3    ; get number of lines in font
   move.l (a7),d1    ; get character to output
   move.l d3,d4
   add.w d4,d4   
   mulu d4,d1        ; times bytes per character
   add.w #130,d1     ; font data starts 130 bytes in
   add.l d1,a2       ; get address of character
   subq.w #1,d3      ; dec line count

1$ clr.w d1
   swap d1
   move.w (a2)+,d1   ; get first line of character
   ror.l d0,d1       ; shift it appropriately
   move.w d1,d2      ; or color mask
   move.l d1,d6
   eor.l #-1,d6      ; and color mask

   btst  #0,d5       ; test plane 0 color
   bne.s 2$

   move.w d6,d1
   and.w (a1),d1
   bra.s 3$
2$ or.w (a1),d1      ; mask the data in
3$ move.w d1,(a1)+   ; write the data out plane0

   btst  #1,d5       ; test plane 1 color
   bne.s 4$

   move.w d6,d1
   and.w (a1),d1
   bra.s 5$
4$ move.w d2,d1
   or.w (a1),d1
5$ move.w d1,(a1)+   ; plane 1

   swap  d2
   swap  d6

   btst  #0,d5       ; test plane 0 color
   bne.s 6$

   move.w d6,d1
   and.w (a1),d1
   bra.s 7$
6$ move.w d2,d1
   or.w (a1),d1
7$ move.w d1,(a1)+

   btst  #1,d5       ; test plane 1 color
   bne.s 8$

   move.w d6,d1
   and.w (a1),d1
   bra.s 9$
8$ move.w d2,d1
   or.w (a1),d1
9$ move.w d1,(a1)
   adda.l #154,a1

   dbra d3,1$        ; repeat for all lines
   bra.s pem

ph
   mulu  #160,d0     ; calc address offset

   adda.l d0,a1      ; calc absolute screen address

   clr.w d1
   swap d1
   move.w (a0),d0    ; get x coordinate
   move.w d0,d1
   lsr.w #3,d1
   adda.l d1,a1      ; get screen address
   and.w #$7,d0      ; get pixel within group

   move.l 8(a0),a2   ; get address of font
   clr.w d3
   swap  d3
   move.w (a2),d3    ; get number of lines in font
   move.l (a7),d1    ; get character to output
   move.l d3,d4
   add.w d4,d4
   mulu d4,d1        ; times bytes per character
   add.w #130,d1     ; font data starts 130 bytes in
   add.l d1,a2       ; get address of character
   subq.w #1,d3      ; dec line count

1$ clr.w d1
   swap d1
   move.w (a2)+,d1   ; get first line of character
   ror.l d0,d1       ; shift it appropriately
   ror.l #8,d1
   or.b (a1),d1      ; mask the data in
   move.b d1,(a1)+   ; write the data out plane0
   ror.l #8,d1
   or.b (a1),d1
   move.b d1,(a1)+
   adda.l #79,a1

   dbra d3,1$        ; repeat for all lines in font
pem:
   move.l (a7)+,d0   ; get output character
   movea.l 8(a0),a1  ; get address of font
   addq.l #2,a1
   adda.l d0,a1
   clr.w d1
   move.b (a1),d1    ; get width of character
   add.w 4(a0),d1    ; add tracking
   add.w (a0),d1     ; add old x
   move.w d1,(a0)    ; save new x coordinate
   rts               ; and finished

*
*  PEMIT ( c -- ) outputs proportional stuff
*
   dc.b $85
   dc.b 'PEMIT'
   dc.l vtotal-12

pemit:
   move.l (a7)+,d0
   bsr propout
   doNext

pdata dc.w 0  ; 0 x
      dc.w 0  ; 2 y
      dc.w 1  ; 4 track
      dc.w 0  ; 6 lead
      dc.l 0  ; 8 pointer to font
      dc.w 0  ; 12 flags
      dc.w 15 ; 14 text color

*
*  _TX ( -- addr )
*
   dc.b $83
   dc.b '_TX'
   dc.l pemit-10

tx dc.w $41fa,pdata-*-2
   move.l a0,-(a7)
   doNext

*
*  _TY ( -- addr )
*
   dc.b $83
   dc.b '_TY'
   dc.l tx-8

ty dc.w $41fa,pdata-*
   move.l a0,-(a7)
   doNext

*
*  _TRACK ( -- addr )
*
   dc.b $86
   dc.b '_TRACK',0
   dc.l ty-8

track dc.w $41fa,pdata-*+2
   move.l a0,-(a7)
   doNext

*
*  _LEAD ( -- addr )
*
   dc.b $85
   dc.b '_LEAD'
   dc.l track-12

lead dc.w $41fa,pdata-*+4
   move.l a0,-(a7)
   doNext

*
*  _PROP ( -- addr )
*
   dc.b $85
   dc.b '_PROP'
   dc.l lead-10

prop dc.w $41fa,pdata-*+6
   move.l a0,-(a7)
   doNext
*
*  _TCOL
*
   dc.b $85
   dc.b '_TCOL'
   dc.l prop-10

tcol dc.w $41fa,pdata-*+12
   move.l a0,-(a7)
   doNext

*
*     _X ( -- addr ) variable holding text editor's cursor x posn
*
   dc.b $82
   dc.b '_X',0
   dc.l tcol-10

vx bra doColon
   dc.l aVara,0

*
*     _Y ( --- addr ) variable holding text editor's cursor y posn
*
   dc.b $82
   dc.b '_Y',0
   dc.l vx-8

vy bra doColon
   dc.l aVara,0

*
*     ENTER ( string --- bytesRead ) enters a file into the text buffer
*               " FILENAME.4TH" ENTER
   dc.b $85
   dc.b 'ENTER'
   dc.l vy-8

enter bra doColon
   dc.l open,read,toR,close,drop,rFrom
   dc.l buffer,plus,vtotal,store,buffer,vmark,store
   dc.l zero,vy,store,exit

*
*     READ ( handle --- bytesRead )
*
   dc.b $84
   dc.b 'READ',0
   dc.l enter-10

read
*  move.l (a7)+,d0 ; save handle ( this redef will save 30 bytes )
* move.l bigBuff,-(a7) ; buffer address
* move.l #buffSize,-(a7) ; bytes to read
* move.w d0,-(a7) ; handle
* move.w #63,-(a7) ; read command
* trap #1 ; do it
* add.l #12,a7 ; fix stack
* doNext

 bra doColon
   dc.l dup,toR,buffer,lit,120000,rFrom,lToW,lit,63,lToW,six,gemdos,exit

*
*     LOAD ( -- )
*
   dc.b $84
   dc.b 'LOAD',0
   dc.l read-10

load  bra doColon
   dc.l tib,fetch,toR,buffer,tib,store,zero,toIn,store
   dc.l interpret,rFrom,tib,store,exit

*
*  ?KEY  ( --- f ) returns true if a key is ready
*
   dc.b $84
   dc.b '?KEY",0
   dc.l load-10

qKey move.w #2,-(a7)
 move.w #1,-(a7)
 trap #13
 addq.l #4,a7
 move.l d0,-(a7)
 doNext

*
*  _OUT1 ( -- addr ) variable containing output device 1
*
   dc.b $85
   dc.b '_OUT1'
   dc.l qKey-10

vOut1 bra doColon
   dc.l aVara,2    ; default device is console

*
*  _OUT2 ( -- addr ) variable containing output device 2
*
   dc.b $85
   dc.b '_OUT2'
   dc.l vOut1-10

vOut2 bra doColon
   dc.l aVara,-1   ; default device is null

*
*  _IN ( -- addr ) variable containing input device
*
   dc.b $83
   dc.b '_IN'
   dc.l vOut2-10

vIn bra doColon
   dc.l aVara,2   ; default device is con:

*
*  W@  ( addr --- n16 ) fetches 16 bit value n from addr
*
   dc.b $82
   dc.b 'W@',0
   dc.l vIn-8

wFetch clr.w d0
 swap d0
 move.l (a7),a0
 move.w (a0),d0
 move.l d0,(a7)
 doNext

*
*  W! ( n16 addr --- ) moves 16 bits of n to addr
*
   dc.b $82
   dc.b 'W!',0
   dc.l wFetch-8

wStore move.l (a7)+,a0
 move.l (a7)+,d0
 move.w d0,(a0)
 doNext

*
*  W, ( n16 --- ) stores n16 into the next available dictionary locn
*
   dc.b $82
   dc.b 'W,',0
   dc.l wStore-8

wComma move.l (a7)+,d0
 dc.w $41fa,nextFree-*-2
* lea nextFree(PC),a0 ; get DP
 move.l (a0),a1       ; get HERE
 move.w d0,(a1)+      ; store n16
 move.l a1,(a0)       ; store new DP
 doNext

*
*     STARTREZ ( --- addr ) returns a variable containing powerup resolution
*
   dc.b $88
   dc.b 'STARTREZ',0
   dc.l wComma-8

startRez dc.w $41fa,_startRez-*-2
* lea _startRez(PC),a0
   move.l a0,-(a7)
   doNext

*
*     AINIT ( --- addr ) initializes the line-A graphics routines
*
   dc.b $85
   dc.b 'AINIT'
   dc.l startRez-14

ainit movem.l a3-a6,-(a7) ; protect vital registers
   dc.w $a000             ; initialize lineA gunk
   movem.l (a7)+,a3-a6    ; restore registers
   move.l a0,-(a7)        ; push address of lineA variables
   doNext

*
*     GETPIXEL ( --- n ) returns the color of a point on the screen
*
   dc.b $88
   dc.b 'GETPIXEL',0
   dc.l ainit-10

getpixel dc.w $41fa,lineaptr-*-2
* lea lineaptr(PC),a0
   move.l (a0),a0
   move.l 12(a0),a0 ; get pointer to PTSIN array
   move.l (a7)+,d1  ; get Y
   move.l (a7)+,d0  ; get X
   move.w d0,(a0)+  ; save X in PTSIN
   move.w d1,(a0)   ; save Y in PTSIN
   dc.w $a002       ; fetch the point
   swap d0
   clr.w d0
   swap d0
   move.l d0,-(a7)  ; save the color
   doNext

*
*     DRAWLINE ( --- ) plots a line on the screen based on the contents of
*                      the array pointed to by AINIT
   dc.b $88
   dc.b 'DRAWLINE',0
   dc.l getpixel-14

drawline movem.l a3-a6,-(a7)
   dc.w $a003
   movem.l (a7)+,a3-a6
   doNext

*
*     HLINE ( -- ) draws a horizontal line
*
   dc.b $85
   dc.b 'HLINE'
   dc.l drawline-14

hline movem.l a3-a6,-(a7)
   dc.w $a004
   movem.l (a7)+,a3-a6
   doNext

*
*     FRECT ( - ) draws a filled rectangle
*
   dc.b $85
   dc.b 'FRECT'
   dc.l hline-10

frect movem.l a3-a6,-(a7)
   dc.w $a005
   movem.l (a7)+,a3-a6
   doNext

*
*     FPOLY ( - ) draws a filled polygon
*
   dc.b $85
   dc.b 'FPOLY'
   dc.l frect-10

fpoly movem.l a3-a6,-(a7)
   dc.w $a006
   movem.l (a7)+,a3-a6
   doNext

*
*     SHOWMOUSE ( --- ) enables display of the mouse cursor,
*                             without enabling GEM. addr is from AINIT
   dc.b $89
   dc.b 'SHOWMOUSE'
   dc.l fpoly-10

showmouse movem.l a3-a6,-(a7)
   dc.w $a000             ; get address of lineA array
   move.l 8(a0),a0        ; get address of INTIN array
   clr.w (a0)             ; set to show mouse immediately
   dc.w $a009
   movem.l (a7)+,a3-a6
   doNext

*
*     HIDEMOUSE ( --- ) hides the cursor
*
   dc.b $89
   dc.b 'HIDEMOUSE'
   dc.l showmouse-14

hidemouse movem.l a3-a6,-(a7)
   dc.w $a00a
   movem.l (a7)+,a3-a6
   doNext

*
*     PLOT     ( x y -- ) plots a pixel at x, y
*
   dc.b $84
   dc.b 'PLOT',0
   dc.l hidemouse-14

plot move.l (a7)+,d1 ; get y
     move.l (a7)+,d0 ; get x
     dc.w $41fa,intrnclr-*
*    lea intrnclr+2(PC),a0
     move.w (a0),d2  ; get color
     bsr pset        ; plot the point
     doNext

*
*     LINE ( x1 y1 x2 y2 --- ) draw a line between (x1,y1) and (x2,y2)
*
   dc.b $84
   dc.b 'LINE',0
   dc.l plot-10

line:
   dc.w $41fa,clipParms+2-*-2 ; +2 gives us a word into long offset
*  lea clipParms+2(PC),a0 ; point to clipping variables
   move.l (a7)+,a1  ; get y2
   move.l (a7)+,a2  ; get x2
   move.l (a7)+,d3  ; get y1
   move.l (a7)+,d2  ; get x1

   move.w d2,d6     ; get start point
   move.w d3,d7
   bsr rel_pos      ; get posn of point
   move.w d1,d0     ; save code1

   move.w a2,d6     ; get posn of second point
   move.w a1,d7
   bsr rel_pos      ; code2 is in d1

   tst.w d1         ; if points aren't in drawing area, don't draw the line
   bne.s testw1
   tst.w d0         ; code1 is in d0
   beq drawit2      ; if both points visible, draw the line

testw1 move.w d0,d2 ; if both points on the same page outside the viewing
   and.w d1,d2      ; window, then do not draw.
   beq outeh

   movem.l a3-a6,-(a7)
   move.w d1,30(a0) ; save code2
   move.w d0,28(a0) ; save code1
   move.w a2,a3     ; set up registers
   move.w a1,a3
   move.w d2,a6
   move.w d3,a1
   move.w a2,a4
   move.w a3,a5

   tst.w d1         ; test code2 - is point 2 visible?
   bne.s testw2
   move.w a2,16(a0) ; yes, store
   move.w a3,18(a0)
   bra.s testw3

testw2 move.w d1,26(a0) ; save p1code
   move.w d0,24(a0)     ; save p2code
   bsr find_pnt
   tst.w 24(a0)         ; test p1code
   bne.s drawend

   move.w d2,16(a0)     ; store rightx
   move.w d3,18(a0)     ; store righty

testw3 move.w a4,d2
   move.w a5,d3
   move.w a0,a2
   move.w a1,a3
   move.w 30(a0),24(a0) ; code2,p1code
   move.w 28(a0),26(a0) ; code1,p2code

   tst.w 26(a0)         ; test p2code
   bne testw4
   move.w a2,20(a0)
   move.w a3,22(a0)     ; save leftx,lefty
   bra.s drawit1

testw4 bsr find_pnt
   move.w d2,20(a0)
   move.w d3,22(a0)

drawit1 move.w 20(a0),d2 ; connect points with a line
   move.w 22(a0),d3
   move.l #0,a2
   move.l #0,a3
   move.w 16(a0),a2
   move.w 18(a0),a1

   movem.l (a7)+,a3-a6   ; fix registers
   bra.s drawit2

drawend movem.l (a7)+,a3-a6
outeh doNext

drawit2:
   dc.w $41fa,lineaptr-*-2
*  lea lineaptr(PC),a0
   move.l (a0),a0
   move.w d2,42(a0) ; save x1
   move.w d3,44(a0) ; save y1
   move.w a2,38(a0) ; save x2
   move.w a1,40(a0) ; save y2
   move.w #$ffff,32(a0) ; set last line
   clr.w 36(a0)     ; set xfer mode
   move.w #$ffff,34(a0) ; set line mask
   dc.w $a003       ; draw a line
   doNext

rel_pos:
   clr.l d1         ; determines the position of the point passed
   move.w d7,d1     ; in d6,d7 relative to the drawing window
   sub.w 4(a0),d1   ; test against top y
   lsl.l #1,d1
   move.w d7,d1
   sub.w 12(a0),d1  ; test against bottom y
   neg.w d1
   lsl.l #1,d1
   move.w d6,d1
   sub.w 8(a0),d1   ; test against right x
   neg.w d1
   lsl.l #1,d1
   move.w d6,d1
   sub.w (a0),d1    ; test against left x
   lsl.l #1,d1
   swap d1
   rts

find_pnt move.w d2,d4  ; find the center point of
   move.w d3,d5
   add.w a2,d4         ; the line p1 p2  (x1+x2)/2
   ext.l d4

   lsr.l #1,d4
   add.w a3,d5         ; (y1+y2)/2
   ext.l d5            ; =center point of line p1 p2

   lsr.l #1,d5
   move.w d4,d6
   move.w d5,d7
   bsr.s rel_pos

   move.w 26(a0),d6
   and.w d1,d6
   bne.s fother

   cmp.w d4,d2
   bne.s findw1
   cmp.w d5,d3
   beq.s fendit

findw1 cmp.w d4,a2
   bne.s findw2
   cmp.w d5,a3
   bne.s findw2
   bra.s fendit

findw2 move.w d4,d2
   move.w d5,d3
   move.w d1,24(a0)
   bra.s find_pnt

fother cmp.w d4,a2
   bne.s fother1
   cmp.w d5,a3
   beq.s fendit
fother1 cmp.w d4,d2
   bne.s fother2
   cmp.w d5,d3
   beq.s fendit

fother2 tst.w 24(a0)
   beq.s fother3
   move.w d1,d7
   and.w 24(a0),d7
   bne.s fexit
fother3 move.w d4,a2
   move.w d5,a3
   move.w d1,26(a0)
   bra.s find_pnt

fexit move.w #1,24(a0)

fendit rts

*
*  SETCLIP ( ulx uly lrx lry --- ) set clipping parameters for line draw
*
   dc.b $87
   dc.b 'SETCLIP'
   dc.l line-10

setclip dc.w $41fa,clipEnd-*-2
*  lea clipEnd(PC),a0
   move.l (a7)+,-(a0)
   move.l (a7)+,-(a0)
   move.l (a7)+,-(a0)
   move.l (a7)+,-(a0)
   doNext

clipParms dc.l 0,0,319,199  ; space for ulx,uly,lrx,lry
clipEnd   dc.l 0,0,0,0      ; space for clipping calcs

*
*  SETLOG ( addr --- )
*
   dc.b $86
   dc.b 'SETLOG',0
   dc.l setclip-12

setlog move.l (a7)+,d0 ; get screen logical base
 dc.w $41fa,_scrnbase-*-2
* lea _scrnbase(PC),a0
 move.l d0,(a0)        ; save new screen logical base

 move.w #-1,-(a7)
 move.l #-1,-(a7)
 move.l d0,-(a7)
 move.w #5,-(a7)
 trap #14
 add.l #12,a7  ; fix stack
 doNext

*
*     FILLRECT ( addr n x1 y1 x2 y2 -- ) addr is the pointer to the mask
*                                n is the number of lines in the pattern
   dc.b $88
   dc.b 'FILLRECT',0
   dc.l setlog-12

fillrect dc.w $41fa,lineaptr-*-2
* lea lineaptr(PC),a0
   move.l (a0),a0
   move.l (a7)+,d1  ; get y2
   move.l (a7)+,d0  ; get x2
   move.w d0,42(a0) ; save x2
   move.w d1,44(a0) ; save y2
   move.l (a7)+,d1  ; get y1
   move.l (a7)+,d0  ; get x1
   move.w d0,38(a0) ; save x1
   move.w d1,40(a0) ; save y1
   move.l (a7)+,d0  ; get # of lines of pattern
   move.w d0,50(a0)
   clr.w 36(a0)     ; set xfer mode
   move.l (a7)+,46(a0)  ; point to pattern mask
   clr.w 54(a0)     ; set no clipping
   dc.w $a005       ; do a filled rectangle
   doNext
*
*     SEEDFILL ( pattAddr n x1 y1 )
*
   dc.b $88
   dc.b 'SEEDFILL',0
   dc.l fillrect-14

seedfill dc.w $41fa,lineaptr-*-2
* lea lineaptr(PC),a0
   move.l (a0),a0
   move.l (a7)+,d1  ; get y1
   move.l (a7)+,d0  ; get x1
   move.w d0,38(a0) ; save x1
   move.w d1,40(a0) ; save y1
   move.l (a7)+,d0  ; get # of lines of pattern
   move.w d0,50(a0)
   clr.w 36(a0)     ; set xfer mode
   move.l (a7)+,46(a0)  ; point to pattern mask
   clr.w 54(a0)     ; set no clipping
   dc.w $a00f       ; do seed fill
   doNext

*
*     FRAME ( x1 y1 x2 y2 --- ) draws a frame
*
   dc.b $85
   dc.b 'FRAME'
   dc.l seedfill-14

frame bra doColon
   dc.l three,pick,three,pick,three,pick,five,pick,line ; -
   dc.l three,pick,three,pick,five,pick,three,pick,line ; |-
   dc.l one,pick,three,pick,three,pick,three,pick,line  ; |-|
   dc.l three,pick,one,pick,three,pick,over,line        ; _
   dc.l drop,drop,drop,drop,exit

*
*     SETCOLOR ( n -- ) sets current plotting color to n
*
   dc.b $88
   dc.b 'SETCOLOR',0
   dc.l frame-10

setColor move.l (a7)+,d0 ; get color
  dc.w $41fa,intrnclr-2-*
* lea lineaptr(PC),a0
  move.l d0,(a0)    ; set color for PLOT

 dc.w $41fa,lineaptr-*-2
* lea lineaptr(PC),a0
  move.l (a0),a0
  move.l 8(a0),a1   ; get pointer to INTIN array
  move.w d0,(a1)    ; set color in INTIN

  move.b d0,d1
  andi.w #1,d0
  move.w d0,24(a0)  ; set _FG_BP_0
  move.b d1,d0
  asr.b #1,d0
  andi.w #1,d0
  move.w d0,26(a0)  ; set _FG_BP_1
  move.b d1,d0
  asr.b #2,d0
  andi.w #1,d0
  move.w d0,28(a0)  ; set _FG_BP_2
  move.b d1,d0
  asr.b #3,d0
  andi.w #1,d0
  move.w d0,30(a0)  ; set _FG_BP_3
  doNext

*
*  UNSPRITE ( addr --- )
*
   dc.b $88
   dc.b 'unsprite',0
   dc.l setColor-14

unsprite2 move.l (a7)+,a1   ; get address of undraw buffer
   dc.w $41fa,_rez-2-*
   move.l (a0),d1          ; get resolution

1$ move.l (a1)+,d0         ; get magic
   cmp.l #'FT87',d0        ; is it there?
   bne.s 2$                ; nope. go away.

   move.l (a1)+,a0         ; get screen address to unsprite to
   moveq #$f,d0            ; set up count register

   dbra  d1,3$             ; branch if medium res

4$ move.l (a1)+,(a0)+      ; restore a line
   move.l (a1)+,(a0)+
   move.l (a1)+,(a0)+
   move.l (a1)+,(a0)
   add.l #152,a0           ; point to next line
   dbra  d0,4$
   bra.s 2$

3$ move.l (a1)+,(a0)+      ; restore a line
   move.l (a1)+,(a0)       ; restore the rest of the line
   add.l #156,a0           ; point to next line

   dbra d0,3$

2$ doNext

*
*  UNSPRITE ( addr --- )
*
   dc.b $88
   dc.b 'UNSPRITE',0
   dc.l unsprite2-14

unsprite move.l (a7)+,a2   ; get address of undraw buffer
   move.l a6,-(a7)
   move.l a4,-(a7)
   dc.w $a00c
   move.l (a7)+,a4
   move.l (a7)+,a6
   doNext

dosprite:
   dc.w $43fa,_rez-2-*
   move.l (a1),d4    ; get screen resolution

   dc.w $43fa,_scrnbase-2-*
   move.l (a1),a1    ; get screen base address

   cmp.b #2,d4       ; is it monochrome?
   beq   sh          ; branch if yes

   mulu  #160,d1     ; calc address offset

   adda.l d1,a1      ; calc absolute screen address

   clr.w d1
   swap d1
   move.w d0,d1      ; save x coordinate

   dbra d4,sm        ; branch if it's medium rez

   lsr.w #3,d1
   and.w #$f8,d1     ; calc pixel group
   adda.l d1,a1      ; get screen address
   and.w #$f,d0      ; get pixel within group

* a0 = mask  a1 = screen address a2 = undraw a3 = image
* d0 = pixels to rotate  d1 = work d2 = mask d3 =plane0 d4=plane1

   move.l a0,a3      ; get address of sprite
   adda.l #32,a3     ; compute address of image

   move.l #'FT87',(a2)+ ; save magic sprite buffer ID
   move.l a1,(a2)+   ; save address sprite came from

   moveq #15,d5      ; number of lines in an image

1$ moveq #-1,d1
   clr.w d3
   swap d3
   move.w (a0)+,d1   ; get mask
   ror.l d0,d1       ; shift it appropriately
   move.l d1,d2      ; save mask data
   move.w (a3)+,d3   ; get plane 0 image data
   ror.l d0,d3       ; shift it
   move.w (a1),(a2)+ ; save screen data in undraw buffer
   and.w (a1),d1     ; mask screen data
   or.w d3,d1        ; or the data in
   move.w d1,(a1)+   ; write the data out plane0

   clr.w d4
   swap d4
   move.w (a1),(a2)+ ; save data in undraw
   move.w (a3)+,d4   ; get plane1 data
   ror.l d0,d4       ; shift it
   move.w d2,d1      ; get mask data back
   and.w (a1),d1     ; mask data
   or.w d4,d1        ; or the screen data in
   move.w d1,(a1)+   ; write the data out plane1

   clr.w d5
   swap  d5
   move.w (a1),(a2)+ ; save data in undraw
   move.w (a3)+,d5   ; get plane2 data
   ror.l d0,d5       ; shift it
   move.w d2,d1      ; get mask data back
   and.w (a1),d1     ; mask data
   or.w  d5,d1       ; or the data in
   move.w d1,(a1)+   ; write the data out  (plane2)

   clr.w d6
   swap  d6
   move.w (a1),(a2)+ ; save data in undraw
   move.w (a3)+,d6   ; get plane3 data
   ror.l d0,d6       ; shift it
   move.w d2,d1      ; get mask data back
   and.w (a1),d1     ; mask data
   or.w  d6,d1       ; or the data in
   move.w d1,(a1)+   ; write the data out  (plane3)

   swap  d2          ; get the other half of the mask
   swap  d3          ; other half of plane0
   swap  d4          ; other half of plane1
   swap  d5          ; other half of plane2
   swap  d6          ; other half of plane3

   move.w (a1),(a2)+ ; save data in undraw
   move.w d2,d1      ; get mask data
   and.w (a1),d1     ; mask screen data
   or.w d3,d1
   move.w d1,(a1)+   ; write the data plane0

   move.w (a1),(a2)+
   move.w d2,d1
   and.w (a1),d1
   or.w d4,d1
   move.w d1,(a1)+

   move.w   (a1),(a2)+
   move.w   d2,d1
   and.w    (a1),d1
   or.w     d5,d1
   move.w   d1,(a1)+

   move.w   (a1),(a2)+
   move.w   d2,d1
   and.w    (a1),d1
   or.w     d5,d1
   move.w   d1,(a1)

   adda.l #146,a1

   dbra d5,1$        ; repeat for all lines
   rts

sm lsr.w #2,d1
   and.w #$fc,d1     ; calc pixel group
   adda.l d1,a1      ; get screen address
   and.w #$f,d0      ; get pixel within group

* a0 = mask  a1 = screen address a2 = undraw a3 = image
* d0 = pixels to rotate  d1 = work d2 = mask d3 =plane0 d4=plane1

   move.l a0,a3      ; get address of sprite
   adda.l #32,a3     ; compute address of image

   move.l #'FT87',(a2)+ ; save magic sprite buffer ID
   move.l a1,(a2)+   ; save address sprite came from

   moveq #15,d5      ; number of lines in an image

1$ moveq #-1,d1
   clr.w d3
   swap d3
   move.w (a0)+,d1   ; get mask
   ror.l d0,d1       ; shift it appropriately
   move.l d1,d2      ; save mask data
   move.w (a3)+,d3   ; get plane 0 image data
   ror.l d0,d3       ; shift it
   move.w (a1),(a2)+ ; save screen data in undraw buffer
   and.w (a1),d1     ; mask screen data
   or.w d3,d1        ; or the data in
   move.w d1,(a1)+   ; write the data out plane0

   clr.w d4
   swap d4
   move.w (a1),(a2)+ ; save data in undraw
   move.w (a3)+,d4   ; get plane1 data
   ror.l d0,d4       ; shift it
   move.w d2,d1      ; get mask data back
   and.w (a1),d1     ; mask data
   or.w d4,d1        ; or the screen data in
   move.w d1,(a1)+   ; write the data out plane1

   swap d2           ; get the other half of the mask
   swap d3           ; other half of plane0
   swap d4           ; other half of plane1

   move.w (a1),(a2)+ ; save data in undraw
   move.w d2,d1      ; get mask data
   and.w (a1),d1     ; mask screen data
   or.w d3,d1
   move.w d1,(a1)+   ; write the data plane0

   move.w (a1),(a2)+
   move.w d2,d1
   and.w (a1),d1
   or.w d4,d1
   move.w d1,(a1)

   adda.l #154,a1

   dbra d5,1$        ; repeat for all lines
   rts

sh
   rts               ; and finished

*
*  SPRITE ( x y defn buffer --- )
*
   dc.b $86
   dc.b 'sprite',0
   dc.l unsprite-14

sprite2 move.l (a7)+,a2 ; point to undraw buffer
   move.l (a7)+,a0   ; point to defn
   move.l (a7)+,d1   ; get y
   move.l (a7)+,d0   ; get x
   dc.w $43fa,clipParms-*-2
*  lea clipParms(PC),a1
   cmp.l 8(a1),d0    ; is x out to lunch (right)?
   bgt.s 1$          ; br if yes
   cmp.l (a1),d0     ; is x out to lunch (left)?
   blt.s 1$
   cmp.l 4(a1),d1    ; top?
   blt.s 1$
   cmp.l 12(a1),d1   ; bottom?
   bgt.s 1$

   movem.l a3,-(a7)
   bsr dosprite      ; draw the sprite
   movem.l (a7)+,a3

1$ doNext

*
*  SPRITE ( x y defn buffer --- )
*
   dc.b $86
   dc.b 'SPRITE',0
   dc.l sprite2-12

sprite move.l (a7)+,a2 ; point to undraw buffer
   move.l (a7)+,a0   ; point to defn
   move.l (a7)+,d1   ; get y
   move.l (a7)+,d0   ; get x
   dc.w $43fa,clipParms-*-2
*  lea clipParms(PC),a1
   cmp.l 8(a1),d0    ; is x out to lunch (right)?
   bgt.s 1$          ; br if yes
   cmp.l (a1),d0     ; is x out to lunch (left)?
   blt.s 1$
   cmp.l 4(a1),d1    ; top?
   blt.s 1$
   cmp.l 12(a1),d1   ; bottom?
   bgt.s 1$

   movem.l a3-a6,-(a7)
   dc.w $a00d        ; draw the sprite
   movem.l (a7)+,a3-a6

1$ doNext
*
*     BLIT   ( addr -- ) addr points to the user's parameter block
*                 format of parameter block:
*                      0:  SX   source x
*                      4:  SY   source y
*                      8:  SH   source height
*                      C:  SW   source width
*                     10:  DX   destination x
*                     14:  DY   destination y
*                     18:  MODE transfer op code
*                     1C:  SADD source screen address
*                     20:  DADD dest screen address
   dc.b $84
   dc.b 'BLIT',0
   dc.l sprite-12

blit: dc.w $41fa,_rez-*-2
* lea _rez(PC),a0        ; get current screen resolution
   move.l (a0),d3
   dbra  d3,medBlt

lowBlt move.l (a7)+,a0   ; get address of user's pblock
   move.l a6,d6          ; save for later
   dc.w $4dfa,b_wd-*-2
* lea b_wd(PC),a6        ; get address of lineA's stuff

   move.w 2(a0),14(a6)   ; move x    ~  move user's variables
   move.w 6(a0),16(a6)   ; move y
   move.w 10(a0),2(a6)   ; move sh
   move.w 14(a0),0(a6)   ; move sw
   move.w 18(a0),28(a6)  ; move dx
   move.w 22(a0),30(a6)  ; move dy
   move.b 27(a0),d0      ; get transfer mode
   move.b d0,10(a6)
   move.b d0,11(a6)
   move.b d0,12(a6)
   move.b d0,13(a6)
   move.l 28(a0),18(a6)  ; move source screen address
   move.l 32(a0),32(a6)  ; move dest screen address

   move.w #4,4(a6)       ; number of planes  ~ move requisite cruftiness
   move.w #1,6(a6)
   move.w #2,8(a6)
   move.w #8,22(a6)
   move.w #160,24(a6)
   move.w #2,26(a6)
   move.w #8,36(a6)
   move.w #160,38(a6)
   move.w #2,40(a6)
   move.l #0,42(a6)
   move.w #0,48(a6)
   move.w #0,48(a6)
   move.w #0,50(a6)

   dc.w $a007
   move.l d6,a6
hiBlt:
   doNext

medBlt dbra d3,hiBlt

   move.l (a7)+,a0   ; get address of user's pblock
   move.l a6,d6          ; save for later
   dc.w $4dfa,b_wd-*-2
* lea b_wd(PC),a6        ; get address of lineA's stuff

   move.w 2(a0),14(a6)   ; move x      move user's variables
   move.w 6(a0),16(a6)   ; move y
   move.w 10(a0),2(a6)   ; move sh
   move.w 14(a0),0(a6)   ; move sw
   move.w 18(a0),28(a6)  ; move dx
   move.w 22(a0),30(a6)  ; move dy
   move.b 27(a0),d0      ; get transfer mode
   move.b d0,11(a6)
   move.b d0,12(a6)
   move.l 28(a0),18(a6)  ; move source screen address
   move.l 32(a0),32(a6)  ; move dest screen address

   move.w #2,4(a6)       ; number of planes   move requisite cruftiness
   move.w #1,6(a6)
   move.w #2,8(a6)
   move.b #0,10(a6)
   move.b #0,13(a6)
   move.w #4,22(a6)
   move.w #160,24(a6)
   move.w #2,26(a6)
   move.w #4,36(a6)
   move.w #160,38(a6)
   move.w #2,40(a6)
   move.l #0,42(a6)
   move.w #0,48(a6)
   move.w #0,48(a6)
   move.w #0,50(a6)

   dc.w $a000,$a007
   move.l d6,a6
   doNext

b_wd ds.w 1     ; 0 block width
b_ht ds.w 1     ; 2 block height
plane_ct ds.w 1 ; 4 # of planes
fg_col ds.w 1   ; 6 fg color index
bg_col ds.w 1   ; 8 bg color index
op_tab0 ds.b 1  ; 10 mode for plane 0
op_tab1 ds.b 1  ; 11 mode for plane 1
op_tab2 ds.b 1  ; 12 mode for plane 2
op_tab3 ds.b 1  ; 13 mode for plane 3
s_xmin ds.w 1   ; 14 x of source
s_ymin ds.w 1   ; 16 y of source
s_form ds.l 1   ; 18 source address
s_nxwd ds.w 1   ; 22 source next word
s_nxln ds.w 1   ; 24 source next line
s_nxpl ds.w 1   ; 26 source next plane
d_xmin ds.w 1   ; 28 x of dest
d_ymin ds.w 1   ; 30 y of dest
d_form ds.l 1   ; 32 dest address
d_nxwd ds.w 1   ; 36 dest next word
d_nxln ds.w 1   ; 38 dest next line
d_nxpl ds.w 1   ; 40 dest next plane
p_addr ds.l 1   ; 42 pattern address
p_nxln ds.w 1   ; 46 pattern next line
p_nxpl ds.w 1   ; 48 pattern next plane
p_mask ds.w 1   ; 50 pattern mask
   ds.w 50      ; lineA's mandatory work area

*
*     LINEAPTR ( -- addr ) returns address of ptr to lineA buffer
*                            use: LINEAPTR @
   dc.b $88
   dc.b 'LINEAPTR',0
   dc.l blit-10

aptr dc.w $41fa,lineaptr-*-2
* lea lineaptr(PC),a0
   move.l a0,-(a7)
   doNext

*******************************************************
* plot: color in d2, x in d0, y in d1

pset  dc.w $41fa,_scrnbase-2-*
* lea _scrnbase(PC),a0
  move.l (a0),a1       ; get screen base address
  dc.w $41fa,_rez-2-*
* lea _rez(PC),a0
   move.l (a0),d3
*
   dbra d3,pMedres
pLowres:
   cmp.w #319,d0     ; is x too big?
   bhi 5$            ; abort if off screen
   cmp.w #199,d1     ; is y too big?
   bhi 5$            ; abort if off screen

   swap d2
   move.w d0,d2
   swap d2           ; save x for later

   swap d1
   clr.w d1
   move.l d1,d3      ; save y for later
   swap d1

   swap d0
   move.w d2,d0      ; save color for later
   swap d0

   mulu #160,d1      ; calculate address of line y
   adda.l d1,a1      ; get absolute screen address
   move.w d0,d1      ; copy x
   lsr.w #1,d1
   and.w #$f8,d1     ; calc pixel group
   adda.l d1,a1

   and.w #$f,d0      ; get pixel number within group
   move.w #$8000,d1  ; start the pixel mask off
   ror.w d0,d1       ; move the bit over
   move.w d1,d0
   eor.w #$ffff,d0

   move.w (a1),d3    ; get plane0 from screen
   and.w d0,d3       ; strip old bit out of plane0
   lsr.w #1,d2       ; get bit of color into carry
   bcc.s 1$
   or.w d1,d3        ; set the color bit
1$ move.w d3,(a1)+   ; save the bit

   move.w (a1),d3    ; get plane1 from screen
   and.w d0,d3       ; strip out old bit
   lsr.w #1,d2       ; get bit of color into carry
   bcc.s 2$
   or.w d1,d3
2$ move.w d3,(a1)+

   move.w (a1),d3    ; get plane2
   and.w d0,d3
   lsr.w #1,d2
   bcc.s 3$
   or.w d1,d3
3$ move.w d3,(a1)+

   move.w (a1),d3
   and.w d0,d3
   lsr.w #1,d2
   bcc.s 4$
   or.w d1,d3
4$ move.w d3,(a1)

   swap d0
   move.w d0,d2     ; restore color

   swap d2          ; restore x
   move.w d2,d0
   swap d2

   swap d3          ; restore y
   move.w d3,d1
5$ rts

pMedres dbra d3,pHires
   cmp.w #639,d0   ; is x off screen?
   bhi 3$          ; br if yes
   cmp.w #199,d1   ; is y off screen?
   bhi 3$

   swap d2
   move.w d0,d2
   swap d2           ; save x for later

   swap d1
   clr.w d1
   move.l d1,d3      ; save y for later
   swap d1

   swap d0
   move.w d2,d0      ; save color for later
   swap d0

   mulu #160,d1      ; calculate address of line y
   adda.l d1,a1      ; get absolute screen address
   move.w d0,d1      ; copy x
   lsr.w #2,d1       ; divide x by 4
   and.w #$fc,d1     ; calc pixel group
   adda.l d1,a1

   and.w #$f,d0      ; get pixel number within group
   move.w #$8000,d1  ; start the pixel mask off
   ror.w d0,d1       ; move the bit over
   move.w d1,d0
   eor.w #$ffff,d0

   move.w (a1),d3    ; get plane0 from screen
   and.w d0,d3       ; strip old bit out of plane0
   lsr.w #1,d2       ; get bit of color into carry
   bcc.s 1$
   or.w d1,d3        ; set the color bit
1$ move.w d3,(a1)+   ; save the bit

   move.w (a1),d3    ; get plane1 from screen
   and.w d0,d3       ; strip out old bit
   lsr.w #1,d2       ; get bit of color into carry
   bcc.s 2$
   or.w d1,d3
2$ move.w d3,(a1)

   swap d0
   move.w d0,d2     ; restore color

   swap d2          ; restore x
   move.w d2,d0
   swap d2

   swap d3          ; restore y
   move.w d3,d1
3$ rts

pHires:
   cmp.w #639,d0     ; is x off screen?
   bhi.s 2$
   cmp.w #399,d1     ; is y off screen?
   bhi.s 2$

   swap d2
   move.w d0,d2
   swap d2           ; save x for later

   swap d1
   clr.w d1
   move.l d1,d3      ; save y for later
   swap d1

   swap d0
   move.w d2,d0      ; save color for later
   swap d0

   swap d1
   clr.w d1
   swap d1           ; clear any garbage out of y
   mulu #80,d1       ; calculate address of line y
   adda.l d1,a1      ; get absolute screen address
   move.w d0,d1      ; copy x
   lsr.w #3,d1       ; divide x by 8
   adda.l d1,a1

   and.w #$7,d0      ; get pixel number within group
   move.w #$80,d1    ; start the pixel mask off
   ror.w d0,d1       ; move the bit over
   move.w d1,d0
   eor.w #$ff,d0

   move.b (a1),d3    ; get plane0 from screen
   and.b d0,d3       ; strip old bit out of plane0
   lsr.w #1,d2       ; get bit of color into carry
   bcc.s 1$
   or.b d1,d3        ; set the color bit
1$ move.b d3,(a1)    ; save the bit

   swap d0
   move.w d0,d2     ; restore color

   swap d2          ; restore x
   move.w d2,d0
   swap d2

   swap d3          ; restore y
   move.w d3,d1
2$ rts

*
*     <=   ( n1 n2 --- f )
*
   dc.b $82
   dc.b '<=',0
   dc.l aptr-14

lesseq move.l (a7)+,d0 ; get first value
   move.l (a7),d1
   cmp.l d0,d1
   sle d0
   and.l #1,d0
   move.l d0,(a7)
   doNext

*
*     >= ( n1 n2 --- f )
*
   dc.b $82
   dc.b '>=',0
   dc.l lesseq-8

grtreq move.l (a7)+,d0
   move.l (a7),d1
   cmp.l d0,d1
   sge d0
   and.l #1,d0
   move.l d0,(a7)
   doNext

*
*     EXPECT ( n addr --- )
*
   dc.b $86
   dc.b 'EXPECT',0
   dc.l grtreq-8

expect move.l   (sp)+,d2            * here is where the expect routine starts
      move.l   (sp)+,a1             * max # of chars in d2, address in a1 ***

      move.w   #0,d1                * reset count
1$    move.b   #32,0(a1,d1)         * let's pad buffer with spaces
      addq.w   #1,d1                *
      cmp.w    d1,d2                *
      bne.s    1$                   *

      move.w   #0,d1                * reset current character counter d1 ***
      move.w   #0,d3                * reset total character counter d3

2$    bsr charIn                    * get char

      cmp.b    #13,d0               * is character cr?
      bne.s    3$
      bra      9$

3$    cmp.b    #8,d0                * is character bs?
      bne.s    5$
      tst.w    d1                   * any chars to bs?
      beq.s    2$
      bsr      crbs                 * bs cursor
      cmp      d1,d3                * are we at end of line?
      bne.s    4$
      subq.w   #1,d3                * one total chars less
4$    subq.w   #1,d1                * current char counter -1
      move.b   #32,0(a1,d1)         * clear char
      bra.s    2$

5$    cmp.l    #4915200,d0          * is character cursor left?
      bne.s    6$
      bsr      crsl                 * move cursor left
      subq.w   #1,d1                * cur char-1
      bpl      2$                   * if count not negative, fine
      move.w   #0,d1                * else clear count
      bra      2$

6$    cmp.l    #5046272,d0          * is character cursor right?
      bne.s    8$
      bsr      crsr
      cmp      d1,d3                * at end of line?
      bne.s    7$
      addq.w   #1,d3                * yes, extend buffer by one
7$    addq.w   #1,d1                * bump cursor over
      cmp.w    d1,d2                * reached max chars?
      beq.s    9$                   * yes quit,
      bra      2$                   * else back for more

8$    cmp.b    #31,d0               * is it a valid ascii character?
      ble      2$
      cmp.b    #127,d0
      bge      2$
      move.b   d0,0(a1,d1)          * put valid character in buffer
      move.w   d0,-(sp)             * output character to screen
      move.w   #2,-(sp)
      trap     #1
      addq.l   #4,sp
      addq.w   #1,d3                * inc end of line
      addq.w   #1,d1                * inc current char
      cmp.w    d1,d2                * max chars reached?
      bne      2$                   * branch if no

9$    move.b   #0,0(a1,d3)          * put zero at end of buffer
      move.b   #0,1(a1,d3)
      doNext

crsr  dc.w $41fa,cur-*-2
*     lea cur(PC),a0
      move.l a0,-(sp)
      move.w   #9,-(sp)
      trap     #1
      addq.l   #6,sp
      rts
crsl  dc.w $41fa,cul-*-2
*     lea cul(PC),a0
      move.l a0,-(sp)
      move.w   #9,-(sp)
      trap     #1
      addq.l   #6,sp
      rts
crbs  dc.w $41fa,bs-*-2
*     lea bs(PC),a0
      move.l a0,-(sp)
      move.w   #9,-(sp)
      trap     #1
      addq.l   #6,sp
      rts

cur   dc.b  27,"C",0
cul   dc.b  27,"D",0
bs    dc.b  27,"D",32,27,"D",0

*
*     65536*    ( n --- n*65536 )
*
   dc.b $86
   dc.b '65536*',0
   dc.l expect-12

bigTimes move.l (a7),d0
   swap d0
   clr.w d0
   move.l d0,(a7)
   doNext

*
*     65536/   ( n --- n/65536 )
*
   dc.b $86
   dc.b '65536/',0
   dc.l bigTimes-12

bigDiv move.l (a7),d0
   clr.w d0
   swap d0
   move.l d0,(a7)
   doNext

*
*     DOES>
*
   dc.b $85
   dc.b 'DOES>'
   dc.l bigDiv-12

doesDo bra doColon
   dc.l qComp,rFrom,comma,exit

*
*  VARIABLE
*
   dc.b $88
   dc.b 'VARIABLE',0
   dc.l doesDo-10

variable bra doColon
   dc.l create,zero,comma,exit

*
*     (   comment )
*
   dc.b $c1
   dc.b '('
   dc.l  variable-14

comment bra doColon
   dc.l lit,41,word,exit

*
*     LOWRES
*
   dc.b $86
   dc.b 'LOWRES',0
   dc.l comment-6

lowRes clr.w -(a7)   ; set screen resolution to lowres
   move.l #-1,-(a7)  ; return phys
   move.l #-1,-(a7)  ; and log addresses
   move.w #5,-(a7)
   trap #14
   add.l #12,a7
   dc.w $41fa,_rez-2-*
*  lea _rez(PC),a0
   clr.l (a0)        ; set up resolution
   bra.s cursOn      ; go turn cursor on, then exit

*
*     MEDRES
*
   dc.b $86
   dc.b 'MEDRES',0
   dc.l lowRes-12

medRes move.w #1,-(a7)   ; set screen resolution to medres
   move.l #-1,-(a7)      ; return phys
   move.l #-1,-(a7)      ; and log addresses
   move.w #5,-(a7)
   trap #14
   add.l #12,a7
   dc.w $41fa,_rez-2-*
*  lea _rez(PC),a0
   move.l #1,(a0)        ; set up resolution


cursOn move.w #27,-(a7)  ; output ESC-e to turn cursor on
   move.w #2,-(a7)
   move.w #3,-(a7)
   trap #13
   addq.l #6,a7
   move.w #'e',-(a7)
   move.w #2,-(a7)
   move.w #3,-(a7)
   trap #13
   addq.l #6,a7

   doNext

*
*  -TRAILING ( addr n1 --- addr n2 ) remove trailing blanks from a string
*
   dc.b $89
   dc.b '-TRAILING'
   dc.l medRes-12

trailing move.l (a7),d0 ; get length of string
   move.l 4(a7),a0   ; get address of string
   move.b #$20,d1    ; set up for loop
   bra.s 2$

1$ move.l a0,a1      ; get beginning of string
   adda.l d0,a1      ; point to end of string
   move.b (a1),d1    ; get character at end of string
2$ cmp.b #$20,d1     ; is the character a space?
   dbne d0,1$        ; if yes, keep looping
   cmp.b #0,d1       ; is the character actually a zero?
   dbne d0,1$        ; yes, go try again

   addq.w #1,d0      ; adjust d0 for real length of string
   move.l d0,(a7)    ; save new string length
   doNext

*
*  INBOX? ( x y x1 y1 x2 y2 --- x y f )
*
   dc.b $86
   dc.b '?INBOX',0
   dc.l trailing-14

inbox move.l (a7)+,d1 ;y2
   move.l   (a7)+,d0 ;x2
   move.l   (a7)+,d3 ;y1
   move.l   (a7),d2  ;x1
   move.l   4(a7),d5 ;y
   move.l   8(a7),d4 ;x
   move.l   #1,d7    ; true flag

   cmp.l    d2,d4    ; is x<x1?
   bgt.s    1$       ; br if  no
   clr.b    d7       ; set to false
1$ cmp.l    d0,d4    ; is x>x2?
   blt.s    2$
   clr.b    d7
2$ cmp.l    d3,d5    ; is y<y1?
   bgt.s    3$
   clr.b    d7
3$ cmp.l    d1,d5    ; is y>y2?
   blt.s    4$
   clr.b    d7
4$ move.l   d7,(a7)  ; save flag
   doNext

*
*  GRAFCLEAR ( addr n --- ) clear screen at addr with pattern n
*
   dc.b $89
   dc.b 'GRAFCLEAR'
   dc.l inbox-12

grafclear:
   move.l a3,d3    ; preserve the registers
   move.l a4,d4
   move.l a5,d5
   move.l a6,d6

   move.l (a7)+,d0 ; set up to clear the screen in $1000 byte chunks
   move.l (a7)+,a0 ;                                 (expensive chunks!)

   move.l a7,d7

   move.l a0,a1
   adda.l #4000,a1
   move.l a0,a2
   adda.l #8000,a2
   move.l a0,a3
   adda.l #12000,a3
   move.l a0,a4
   adda.l #16000,a4
   move.l a0,a5
   adda.l #20000,a5
   move.l a0,a6
   adda.l #24000,a6
   move.l a0,a7
   adda.l #28000,a7
   move.w #250,d1

1$ move.l d0,(a0)+   ; clear the screen in chunks
   move.l d0,(a0)+
   move.l d0,(a1)+
   move.l d0,(a1)+
   move.l d0,(a2)+
   move.l d0,(a2)+
   move.l d0,(a3)+
   move.l d0,(a3)+
   move.l d0,(a4)+
   move.l d0,(a4)+
   move.l d0,(a5)+
   move.l d0,(a5)+
   move.l d0,(a6)+
   move.l d0,(a6)+
   move.l d0,(a7)+
   move.l d0,(a7)+

   move.l d0,(a0)+
   move.l d0,(a0)+
   move.l d0,(a1)+
   move.l d0,(a1)+
   move.l d0,(a2)+
   move.l d0,(a2)+
   move.l d0,(a3)+
   move.l d0,(a3)+
   move.l d0,(a4)+
   move.l d0,(a4)+
   move.l d0,(a5)+
   move.l d0,(a5)+
   move.l d0,(a6)+
   move.l d0,(a6)+
   move.l d0,(a7)+
   move.l d0,(a7)+
2$ dbra d1,1$

   move.l d3,a3     ; and fix the registers, thank you very much.
   move.l d4,a4
   move.l d5,a5
   move.l d6,a6
   move.l d7,a7

   doNext

*
*  32768/ ( n --- n/32768 )
*
   dc.b $86
   dc.b '32768/',0
   dc.l grafclear-14

thirty2div move.l (a7),d0
 asr.l #8,d0    ; divide by 32768
 asr.l #7,d0
 move.l d0,(a7)
 doNext

*
* 32768*  ( n --- n*32678 )
*
   dc.b $86
   dc.b '32768*',0
   dc.l thirty2div-12

thirty2tims move.l (a7),d0
 asl.l #8,d0  ; multiply n by 32678
 asl.l #7,d0
 move.l d0,(a7)
 doNext

*
* 8* ( n -- n*8 )
*
   dc.b $82
   dc.b '8*',0
   dc.l thirty2tims-12

ateTimes move.l (a7),d0
   asl.l #3,d0
   move.l d0,(a7)
   doNext

*
*  GETSIN ( N --- sinN )
*
   dc.b $86
   dc.b 'GETSIN',0
   dc.l ateTimes-8

getsin move.l (a7)+,d0
 bsr.s crunchangle
 bsr.s cnvrt90   ; return an angle between 0 and 90 degrees
 add.w d0,d0     ; multiply adjusted angle by 2
 swap d0         ; make sure nothing lives in top word
 clr.w d0
 swap d0
 dc.w $41fa,sintab-*-2
* lea sintab(PC),a0
 adda.l d0,a0    ; add angle*2 to address of sin table
 move.w (a0),d0  ; fetch the answer
 cmp.w #180,d1   ; was original angle >180?
 blt.s 1$
 neg.l d0         ; if yes negate the answer
1$ move.l d0,-(a7) ; save answer
 doNext

crunchangle:
 tst.w d0        ; is angle +ve?
 bmi.s 2$        ; branch if not
1$ cmp.w #360,d0 ; is angle <360?
 blt.s 5$        ; br if yes
 sub.w #360,d0   ; perform d0 mod 360
 bra.s 1$

2$ neg.w d0      ; make angle +ve
3$ cmp.w #360,d0 ; is angle <360?
 blt.s 4$        ; br if yes
 sub.w #360,d0   ; else perform d0 mod 360
 bra.s 3$

4$ neg.w d0
 add.w #360,d0   ; make angle +ve between 0 and 360

5$ move.w d0,d1  ; make a copy of the angle
  rts

cnvrt90 cmp.w #180,d0 ; is angle>180?
 blt.s 1$
 sub.w #180,d0   ; yes, subtract 180
1$ cmp.w #90,d0  ; is angle>90?
 blt.s 2$
 sub.w #180,d0   ; yes, subtract 90
 neg.w d0
2$ rts

coscnvrt90 cmp.w #180,d0 ; do same conversion as for sin
 blt.s 1$
 sub.w #180,d0
1$ cmp.w #90,d0
 blt.s 2$
 sub.w #180,d0
 neg.w d0
2$ sub.w #90,d0  ; now convert numbers from 0-90 to 90-0
 neg.w d0
 rts

*
*  GETCOS ( N --- cosN )
*
   dc.b $86
   dc.b 'GETCOS',0
   dc.l getsin-12

getcos move.l (a7)+,d0
 bsr.s crunchangle
 bsr.s coscnvrt90
 add.w d0,d0     ; multiply adjusted angle by 2
 swap d0         ; make sure nothing lives in top word
 clr.w d0
 swap d0
 dc.w $41fa,sintab-*-2
* lea sintab(PC),a0
 adda.l d0,a0    ; add angle*2 to address of sin table
 move.w (a0),d0  ; fetch the answer
 add.w #90,d1    ; put cos into sin range
 cmp.w #360,d1
 bgt.s 1$
 cmp.w #180,d1   ; was original angle >180?
 blt.s 1$
 neg.l d0        ; if yes negate the answer
1$ move.l d0,-(a7) ; save answer
 doNext

sintab dc.w 0,571,1143,1714,2285,2855,3425,3993,4560,5125,5689,6252,6812
 dc.w 7370,7927,8480,9031,9580,10125,10667,11206,11742,12274,12803,13327
 dc.w 13847,14364,14875,15383,15885,16383,16876,17363,17846,18323,18794
 dc.w 19259,19719,20173,20620,21062,21497,21925,22347,22761,23169,23570
 dc.w 23964,24350,24729,25100,25464,25820,26168,26509,26841,27165,27480
 dc.w 27787,28086,28377,28658,28931,29195,29450,29696,29934,30162,30381
 dc.w 30590,30790,30981,31163,31335,31497,31650,31793,31927,32050,32164
 dc.w 32269,32363,32448,32522,32587,32642,32687,32722,32747,32762,32767

*
*  TOSMOUSE
*
   dc.b $88
   dc.b 'TOSMOUSE',0
   dc.l getcos-12

tosMouse dc.w $41fa,mouseVector-2-*
* lea mouseVector(PC),a0
 move.l a0,-(a7)
 dc.w $41fa,mouseParam-2-*
* lea mouseParam(PC),a0
 move.l a0,-(a7)
 move.w #1,-(a7)  ; set relative mode
 move.w #0,-(a7)
 trap #14
 add.l #12,a7
 doNext

mouseVector:
 move.l d0,-(a7)
 move.l a1,-(a7)
 dc.w $43fa,mX-*-2
* lea mX(PC),a1

 move.b (a0),d0   ; right mouse button
 and.l #1,d0
 move.l d0,8(a1)  ; save it

 move.b (a0),d0   ; left mouse button
 and.l #2,d0
 move.l d0,12(a1) ; save it

 move.b 1(a0),d0  ; x update
 ext.w d0
 ext.l d0
 add.l d0,(a1)
 move.l 16(a1),d0
 cmp.l (a1),d0
 ble.s 1$        ; should be le
 move.l d0,(a1)
1$ move.l 20(a1),d0
 cmp.l (a1),d0
 bge.s 2$         ; should be ge
 move.l d0,(a1)

2$ move.b 2(a0),d0 ; y update
 ext.w d0
 ext.l d0
 add.l d0,4(a1)
 move.l 24(a1),d0
 cmp.l 4(a1),d0
 ble.s 3$
 move.l d0,4(a1)
3$ move.l 28(a1),d0
 cmp.l 4(a1),d0
 bge.s 4$
 move.l d0,4(a1)

4$ move.l (a7)+,a1
 move.l (a7)+,d0
 rts

*
*  GEMMOUSE
*
   dc.b $88
   dc.b 'GEMMOUSE',0
   dc.l tosMouse-14

gemMouse dc.w $41fa,realMouse-2-*
* lea realMouse(PC),a0
 move.l (a0),-(a7)
 dc.w $41fa,mouseParam-2-*
* lea mouseParam(PC),a0
 move.l a0,-(a7)
 move.w #1,-(a7)
 move.w #0,-(a7)
 trap #14
 add.l #12,a7
 doNext

*
*  MOUSEXY ( -- x y )
*
   dc.b $87
   dc.b 'MOUSEXY'
   dc.l gemMouse-14

mousexy dc.w $41fa,mX-2-*
* lea mX(PC),a0
 move.l (a0)+,-(a7)
 move.l (a0),-(a7)
 doNext

*
*  MOUSEXY! ( x y -- )
*
   dc.b $88
   dc.b 'MOUSEXY!',0
   dc.l mousexy-12

mousexyb dc.w $41fa,mX-2-*
* lea mX(PC),a0
 move.l (a7)+,4(a0)
 move.l (a7)+,(a0)
 doNext

*
*  BUTTONS ( -- bl br )
*
   dc.b $87
   dc.b 'BUTTONS'
   dc.l mousexyb-14

buttons dc.w $41fa,mR-2-*
* lea mR(PC),a0
 move.l (a0)+,-(a7)
 move.l (a0),-(a7)
 doNext

lastWord ds.w 0

*
*  MOUSECLIP ( ulx uly lrx lry --- )
*
   dc.b $89
   dc.b 'MOUSECLIP'
   dc.l buttons-12            stored l r u d

mouseclip dc.w $41fa,mLclip-2-*
* lea mLclip(PC),a0
 move.l (a7)+,12(a0)  ; save down
 move.l (a7)+,4(a0)   ; save right
 move.l (a7)+,8(a0)   ; save up
 move.l (a7)+,(a0)    ; save left
 doNext

 

