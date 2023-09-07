         *= $c000
         jmp init

v        = 53248  ; vic $d000
sid      = 54272  ; sid $d400
screen   = 1024   ; screen

delay    .byte 0

gskp     .byte 16
gcnt     .byte 16

tskp     .byte 12
tcnt     .byte 12

sprxl    .byte 0,0
sprxh    .byte 0,0

sprxvl   .byte 0,0
sprxvh   .byte 0,0

sprxal   .byte 0,0
sprxah   .byte 0,0

xthrust  .byte 0,0

spry     .byte 0,0

spryv    .byte 0,0

sprya    .byte 1
spryt    .byte 0,0

sprpg    .byte $80   ;spr pointer page
sproff   .byte 0,0   ;spr pointer offset

sndgate  .byte 128

joybyte  .byte 0     ; tmp holder joyst

colltst  .byte 1,2
collrst  .byte 0     ; tmp holder v+31

scoreh   .byte 0,0
scorel   .byte 0,0

fuel     .byte 0,0

plstate  .byte 0,0

  ; position sprites
sprpos   lda spry,x
         sta v,y
         dey
         lda sprxl,x
         sta v,y
         lda sprxh,x
         ror a
         rol v+16
         rts

acclspr  lda spryv,x
         clc
         adc sprya
         sta spryv,x
         rts

thrspr   lda xthrust,x
         beq doneth
         lda sprxvl,x
         clc
         adc sprxal,x
         sta sprxvl,x
         lda sprxvh,x
         adc sprxah,x
         sta sprxvh,x
         lda spryt,x
         clc
         adc spryv,x
         sta spryv,x
doneth   rts

movspr   lda sprxl,x
         clc
         adc sprxvl,x
         sta sprxl,x
         lda sprxh,x
         adc sprxvh,x
         sta sprxh,x

         lda spry,x
         clc
         adc spryv,x
         sta spry,x
donemv   rts


chkbound lda spry,x
chktop   cmp #50
         bcs chkbot
         lda #50
         sta spry,x
         lda #$00
         sta spryv,x
chkbot   lda spry,x
         cmp #230
         bcc chkleft
         lda #229
         sta spry,x
         lda #$00
         sta spryv,x
chkleft  lda sprxh,x
         cmp #1
         bcs chkright
         lda sprxl,x
         cmp #24
         bcs chkright
         lda #24
         sta sprxl,x
         lda #$00
         sta sprxvl,x
         sta sprxvh,x
chkright lda sprxh,x
         cmp #1
         bcc notright
         lda sprxl,x
         cmp #66
         bcc notright
         lda #65
         sta sprxl,x
         lda #$00
         sta sprxvl,x
         sta sprxvh,x
notright rts

chkcoll  lda collrst
         and colltst,x
         beq donecol
         lda spry,x
         cmp #100
         bcc donecol
         jmp hdlcoll
donecol  rts

hdlcoll  lda #$00
         sta spryv,x
         lda spry,x
         clc
         adc #$f8
         sta spry,x
         cmp #208
         bcc decscore
         lda sprxvl,x
         bne decscore
         jmp addscore

decscore lda scoreh,x
         bne notzero
         lda scorel,x
         beq dnscore
notzero  sei
         sed
         sec
         sbc #1
         sta scorel,x
         lda scoreh,x
         sbc #0
         sta scoreh,x
         cld
         cli
dnscore  rts


addscore sei
         sed
         lda sprxh,x
         cmp #$01
         bcc left
         lda scorel,x
         clc
         adc #$01
         sta scorel,x
         lda scoreh,x
         adc #$00
         sta scoreh,x
         jmp donescr
left     lda sprxl,x
         cmp #$30
         bcs middle
         lda scorel,x
         clc
         adc #10
         sta scorel,x
         lda scoreh,x
         adc #$00
         sta scoreh,x
         jmp donescr
middle   lda scorel,x
         clc
         adc #5
         sta scorel,x
         lda scoreh,x
         adc #0
         sta scoreh,x
donescr  cld
         cli
         lda #0
         sta plstate,x
         rts

wait     lda v+18
         cmp #255
         bne wait
         rts

chkjoy   lda #$00
         sta sprxah,x
         sta sprxal,x
         sta spryt,x
         sta sproff,x
         sta xthrust,x
         lda $dc00,x
         sta joybyte
joyleft  lda #%00000100
         bit joybyte
         bne joyright
         lda sprxal,x
         clc
         adc #255
         sta sprxal,x
         lda sprxah,x
         adc #255
         sta sprxah,x
         lda #$01
         sta sproff,x
joyright lda #%00001000
         bit joybyte
         bne joyfire
         lda sprxal,x
         clc
         adc #1
         sta sprxal,x
         lda sprxah,x
         adc #0
         sta sprxah,x
         lda #$02
         sta sproff,x
joyfire  lda #%00010000
         bit joybyte
         bne endchkjoy
         lda fuel,x
         beq nofuel
         lda #255
         sta spryt,x
         lda sproff,x
         clc
         adc #$03
         sta sproff,x
         lda #$01
         sta xthrust,x
         lda #129
         sta sndgate
         dec fuel,x
endchkjoy rts
nofuel   lda #$01
         sta sprxvl,x
         lda #$00
         sta sprxvh,x
         rts

sprpage  lda sprpg
         clc
         adc sproff,x
         sta $07f8,x
         rts

hdc      cmp #$0a
         bcc nota
         sbc #$39
nota     adc #$30
         rts

hexh     lsr a
         lsr a
         lsr a
         lsr a
         jmp hdc

hexl     and #$0f
         jmp hdc

pdata    ldx #0
         lda scoreh,x
         jsr hexh
         sta 1034
         lda scoreh,x
         jsr hexl
         sta 1035
         lda scorel,x
         jsr hexh
         sta 1036
         lda scorel,x
         jsr hexl
         sta 1037

         ldx #1
         lda scoreh,x
         jsr hexh
         sta 1058
         lda scoreh,x
         jsr hexl
         sta 1059
         lda scorel,x
         jsr hexh
         sta 1060
         lda scorel,x
         jsr hexl
         sta 1061
         rts

rocks    .word 1864,1870,1831,1792,1793
         .word 1754,1755,1796,1836,1876
         .word 1882,1842,1802,1762,1723
         .word 1764,1805,1846,1847,1888
         .word 1849,1810,1851,1892,1933
         .word 1894,1855,1896,1937,1938
         .word 1904,1910,1916,1922

landing  .word 1945,1946,1947,1948,1949
         .word 1957,1958,1959,1960,1961
         .word 1979,1980,1981,1982,1983


bkgrnd   lda #$0f
         ldx #160
         .block
loop1    dex
         sta 56135,x
         cpx #$00
         bne loop1
         ldx #250
loop2    dex
         sta 55975,x
         cpx #$00
         bne loop2
         lda #$0e
         ldx #40
loop3    dex
         sta 55315,x
         cpx #$00
         bne loop3
         lda #$0d
         ldx #20
loop4    dex
         sta 55295,x
         cpx #$00
         bne loop4
         .bend

         ldx #$44
         ldy #0
         .block
loop     dex
         lda rocks,x
         sta $fe
         dex
         lda rocks,x
         sta $fd
         lda #102
         sta ($fd),y
         cpx #$00
         bne loop
         .bend
         ldx #$1e
         .block
loop     dex
         lda landing,x
         sta $fe
         dex
         lda landing,x
         sta $fd
         lda #119
         sta ($fd),y
         cpx #$00
         bne loop
         .bend

         lda #1
         jsr hexl
         sta 1986
         lda #0
         jsr hexl
         sta 1987
         lda #5
         jsr hexl
         sta 1999
         lda #1
         jsr hexl
         sta 2021

         rts

init
         lda #<320
         sta $0318
         lda #>320
         sta $0319    ; nmi to jmpback

         lda #147
         jsr $ffd2    ; clr screen

         lda #$00
         sta v+33     ; blk scr

         lda #21
         sta v+24     ; upper case

         lda #$0f     ; grey
         sta v+32     ; border

         jsr createsprites

         jmp title

gt       .null "**{sh space}rocket landing **"
auth     .null "by bill koontz"
inst1    .null "press fire for thrust"
inst2    .null "thrust left or right"
inst3    .null "try high point landings"
inst4    .null "watch your fuel gage!"
inst5    .null "hit ground minus 1"
inst6    .null "both players must"
inst7    .null "press *up* to start"
inst8    .null "*down* to restart"

title
         lda #155
         jsr $ffd2     ;grey text

         ldx #2        ;row
         ldy #10       ;col
         jsr $e50c     ;pos cursor
         lda #<gt
         ldy #>gt
         jsr $ab1e     ;print gt

         ldx #4
         ldy #15
         jsr $e50c
         lda #<auth
         ldy #>auth
         jsr $ab1e

         ldx #7
         ldy #7
         jsr $e50c
         lda #<inst1
         ldy #>inst1
         jsr $ab1e

         ldx #8
         ldy #7
         jsr $e50c
         lda #<inst2
         ldy #>inst2
         jsr $ab1e

         ldx #9
         ldy #7
         jsr $e50c
         lda #<inst3
         ldy #>inst3
         jsr $ab1e

         ldx #10
         ldy #7
         jsr $e50c
         lda #<inst4
         ldy #>inst4
         jsr $ab1e

         ldx #12
         ldy #7
         jsr $e50c
         lda #<inst5
         ldy #>inst5
         jsr $ab1e

         ldx #14
         ldy #2
         jsr $e50c
         lda #<inst6
         ldy #>inst6
         jsr $ab1e

         ldx #14
         ldy #20
         jsr $e50c
         lda #<inst7
         ldy #>inst7
         jsr $ab1e

         ldx #15
         ldy #20
         jsr $e50c
         lda #<inst8
         ldy #>inst8
         jsr $ab1e


         jsr prtlabel
         jsr pdata
         jsr bkgrnd

         .block
wait     lda #%00000010 ; dwn
         bit $dc00
         bne chkup
         bit $dc01
         bne chkup
         jmp newgame
chkup    lda #%00000001 ; up
         bit $dc00
         bne wait
         bit $dc01
         bne wait
         jmp startgame
         .bend

newgame  lda #$00
         sta scorel
         sta scoreh
         sta scorel+1
         sta scoreh+1
         jmp startgame

;; player fuel sprites

createsprites
         lda #$21
         sta $fe
         lda #$80
         sta $fd
         ldy #$80
         lda #$00
nxtf     dey
         sta ($fd),y
         cpy #$00
         bne nxtf

         lda #$ff
         sta $218b
         sta $21be
         sta $21cb
         sta $21fe

         lda #134
         sta $07fa
         lda #135
         sta $07fb

         lda #10
         sta v+4
         lda #62
         sta v+6
         lda #50
         sta v+5
         sta v+7
         lda #$08
         sta v+16

;; player ship  sprites
movsprb  ldx #192     ; move sprite
nxtsprb  dex          ; data to
         lda ship,x   ; screen ram
         sta sprite,x
         lda shipfl,x
         sta spritefl,x
         cpx #$00
         bne nxtsprb

         lda #$00
         sta v+23
         sta v+29
         lda sprpg  ; data page
sprpnt   sta $07f8
         sta $07f9

sprcol   lda #$0d    ; player 1
         sta v+39    ; ship
         sta v+41    ; fuel

         lda #$0e    ; player 2
         sta v+40    ; ship
         sta v+42    ; fuel

         lda #127    ; setup sound
         sta sid
         lda #1
         sta sid+1
         lda #241
         sta sid+6
         lda #17
         sta sid+5
         lda #15
         sta sid+24

         jsr resetfuel

    ;; enable sprites
         lda #$0f
         sta v+21

         rts

startgame
         ldx #2
         .block
next     dex
         lda #0
         sta sprxh,x
         sta sprxvh,x
         sta sprxal,x
         sta sprxah,x
         sta xthrust,x
         sta spryt,x
         sta sproff,x
         sta delay
         lda #29
         sta sprxl,x
         lda #3
         sta sprxvl,x
         lda #91
         sta spry,x
         lda #$ff
         sta fuel,x
         cpx #$00
         bne next
         .bend

         ldx #$02
         ldy #$04
         lsr v+16
         lsr v+16
         .block
loop     dex
         dey
         jsr sprpos
         cpx #$00
         bne loop
         .bend

         lda #147
         jsr $ffd2  ;clr

         jsr resetfuel
         jsr prtlabel
         jsr pdata
         jsr bkgrnd

         lda #1
         sta plstate
         sta plstate+1

         jmp gameloop

 ;; reset fuel sprites
resetfuel
         .block
         ldy #$00
         lda #$21
         sta $fe
         ldx #$10
next     dex
         lda fuelspr1,x
         sta $fd
         lda #$ff
         sta ($fd),y
         lda fuelspr2,x
         sta $fd
         lda #$ff
         sta ($fd),y
         cpx #$00
         bne next
         .bend

         rts


scr1lbl  .null "pilot 1"
scr2lbl  .null "pilot 2"

prtlabel ldx #$00   ; row
         ldy #2     ; col
         jsr $e50c  ; pos cursor
         lda #<scr1lbl
         ldy #>scr1lbl
         jsr $ab1e  ; print

         ldy #26
         jsr $e50c
         lda #<scr2lbl
         ldy #>scr2lbl
         jsr $ab1e

         rts

gameloop
      ; game over ? 
         lda plstate
         bne notover
         lda plstate+1
         bne notover
         jmp endmis

notover  jsr wait
         dec delay
         bne gameloop
         lda #$01
         sta delay
         dec v+32

         dec gcnt
         dec tcnt
         lda v+31
         sta collrst

         lsr v+16
         lsr v+16

         ldx #$02
         ldy #$04
         lda #128
         sta sndgate
loop     dex
         dey
         lda plstate,x
         beq plover
         jsr chkjoy
         lda gcnt
         bne doneg
         jsr acclspr
doneg    lda tcnt
         bne donet
         jsr thrspr
donet    jsr movspr
         jsr chkbound
         jsr chkcoll
         jsr sprpage
plover   jsr sprpos
         cpx #$00
         bne loop

   ;; update fuel sprites
         lda #$21
         sta $fe
         ldy #$00
         lda fuel
         lsr a
         lsr a
         lsr a
         lsr a
         tax
         lda fuelspr1,x
         sta $fd
         lda #$81
         sta ($fd),y
         lda fuel+1
         lsr a
         lsr a
         lsr a
         lsr a
         tax
         lda fuelspr2,x
         sta $fd
         lda #$81
         sta ($fd),y

         .block
         lda gcnt
         bne doneg
         lda gskp
         sta gcnt
doneg    lda tcnt
         bne donet
         lda tskp
         sta tcnt
donet
         .bend
         lda sndgate
         sta sid+4
         jsr pdata
         inc v+32
nxtloop  jmp gameloop

endmis
         .block
         lda #$ff
         sta delay
loop     jsr wait
         dec delay
         bne loop
         .bend

         jmp title

fuelspr1 .byte $bb,$b8,$b5,$b2
         .byte $af,$ac,$a9,$a6
         .byte $a3,$a0,$9d,$9a
         .byte $97,$94,$91,$8e

fuelspr2 .byte $fb,$f8,$f5,$f2
         .byte $ef,$ec,$e9,$e6
         .byte $e3,$e0,$dd,$da
         .byte $d7,$d4,$d1,$ce


sprite   = $2000
spritefl = $20c0
  ; up no flame
ship     .byte $00,$18,$00,$00
         .byte $66,$00,$00,$42
         .byte $00,$00,$81,$00
         .byte $00,$81,$00,$00
         .byte $81,$00,$00,$81
         .byte $00,$00,$81,$00
         .byte $00,$81,$00,$03
         .byte $81,$c0,$04,$81
         .byte $20,$08,$81,$10
         .byte $08,$81,$10,$10
         .byte $81,$08,$10,$ff
         .byte $08,$23,$a5,$c4
         .byte $24,$00,$24,$28
         .byte $00,$14,$30,$00
         .byte $0c,$00,$00,$00
         .byte $00,$00,$00,$01

    ; left no flame
         .byte $00,$00,$00,$00
         .byte $e0,$00,$01,$98
         .byte $00,$01,$04,$00
         .byte $02,$02,$00,$02
         .byte $02,$00,$01,$02
         .byte $00,$01,$01,$c0
         .byte $01,$01,$30,$03
         .byte $81,$08,$04,$80
         .byte $88,$04,$80,$84
         .byte $08,$40,$c4,$08
         .byte $43,$c2,$08,$5d
         .byte $72,$04,$28,$0e
         .byte $04,$20,$02,$02
         .byte $40,$00,$02,$40
         .byte $00,$01,$80,$00
         .byte $00,$80,$00,$01
    ; right no flame
         .byte $00,$00,$00,$00
         .byte $07,$00,$00,$19
         .byte $80,$00,$20,$80
         .byte $00,$40,$40,$00
         .byte $40,$40,$00,$40
         .byte $80,$03,$80,$80
         .byte $0c,$80,$80,$10
         .byte $81,$c0,$11,$01
         .byte $20,$21,$01,$20
         .byte $23,$02,$10,$43
         .byte $c2,$10,$4e,$ba
         .byte $10,$70,$14,$20
         .byte $40,$04,$20,$00
         .byte $02,$40,$00,$02
         .byte $40,$00,$01,$80
         .byte $00,$01,$00,$01
   ; straight up flame
shipfl   .byte $00,$18,$00,$00
         .byte $66,$00,$00,$42
         .byte $00,$00,$81,$00
         .byte $00,$81,$00,$00
         .byte $81,$00,$00,$81
         .byte $00,$00,$81,$00
         .byte $00,$81,$00,$03
         .byte $81,$c0,$04,$81
         .byte $20,$08,$81,$10
         .byte $08,$81,$10,$10
         .byte $81,$08,$10,$ff
         .byte $08,$23,$a5,$c4
         .byte $24,$18,$24,$28
         .byte $3c,$14,$30,$3c
         .byte $0c,$00,$18,$00
         .byte $00,$18,$00,$01
   ; left flame
         .byte $00,$00,$00,$00
         .byte $e0,$00,$01,$98
         .byte $00,$01,$04,$00
         .byte $02,$02,$00,$02
         .byte $02,$00,$01,$02
         .byte $00,$01,$01,$c0
         .byte $01,$01,$30,$03
         .byte $81,$08,$04,$80
         .byte $88,$04,$80,$84
         .byte $08,$40,$c4,$08
         .byte $43,$c2,$08,$5d
         .byte $72,$04,$2a,$0e
         .byte $04,$27,$02,$02
         .byte $43,$00,$02,$43
         .byte $80,$01,$81,$80
         .byte $00,$81,$00,$01
  ; right flame
         .byte $00,$00,$00,$00
         .byte $07,$00,$00,$19
         .byte $80,$00,$20,$80
         .byte $00,$40,$40,$00
         .byte $40,$40,$00,$40
         .byte $80,$03,$80,$80
         .byte $0c,$80,$80,$10
         .byte $81,$c0,$11,$01
         .byte $20,$21,$01,$20
         .byte $23,$02,$10,$43
         .byte $c2,$10,$4e,$ba
         .byte $10,$70,$54,$20
         .byte $40,$e4,$20,$00
         .byte $c2,$40,$01,$c2
         .byte $40,$01,$81,$80
         .byte $00,$81,$00,$01
