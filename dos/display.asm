            .cpu    "65c02"

            .section    code

put_cr      lda     #13
putc        jmp     display.putchar

            .send

display     .namespace

            .section    dp
src         .word   ?
dest        .word   ?
len         .byte   ?
cur_line    .byte   ?
scroll      .byte   ?

color       .byte   ?
curcol      .byte   ?
cursor      .byte   ?
screen      .word   ?
            .send

TEXT_LUT_FG = $d800
TEXT_LUT_BG = $d840
MAX_LINE    = 60

            .section    code


init
            jsr     purple

            lda     #$14
            sta     color
            lda     #$41
            sta     curcol
            
            lda     #2
            sta     io_ctrl

            rts



set_cursor
        jsr     cursor_off
        sta     cursor
        jmp     cursor_on

cursor_off
        pha
        lda     color
        jsr     update_cursor
        pla
        rts

cursor_on
        pha
        lda     curcol
        jsr     update_cursor
        pla
        rts

update_cursor
        phy
        ldy     #3
        sty     io_ctrl
        ldy     cursor
        sta     (screen),y
        ldy     #2
        sty     io_ctrl
        ply
        rts


print_hex
            pha
            lsr     a
            lsr     a
            lsr     a
            lsr     a
            jsr     _digit
            pla
            and     #$0f
            jsr     _digit
            rts
_digit
            phy
            tay
            lda     _digits,y
            ply
            jmp     putc
_digits                             
            .text   "0123456789abcdef"


putchar
        pha
        phy
        jsr     cursor_off
        jsr     _put
        jsr     cursor_on
        ply
        pla
        rts

_put
        cmp     #32
        bcs     _ascii
        cmp     #$0a
        beq     _cr
        cmp     #$0d
        beq     _cr
        rts

_ascii
        ldy     #2
        sty     io_ctrl
        ldy     cursor
        sta     (screen),y
        iny
        cpy     #80
        beq     _cr
        sty     cursor
        rts
        
_cr
        stz     cursor
        lda     cur_line
        inc     a
        cmp     #MAX_LINE
        beq     _scroll

        sta     cur_line
        ldy     #screen
        lda     #80
        jmp     add
                     
_scroll
        lda     #2
        sta     io_ctrl

        lda     #$c0
        sta     src+1
        sta     dest+1
        stz     dest+0
        lda     #80
        sta     src+0

        phx
        ldx     #21
_y      ldy     #0
_loop   lda     (src),y
        sta     (dest),y
        iny
        cpy     #240
        bne     _loop

        ldy     #src
        lda     #240
        jsr     add
        ldy     #dest
        lda     #240
        jsr     add

        dex
        bne     _y
        plx
        
        rts

add
        clc
        adc     0,y
        sta     0,y
        lda     1,y
        adc     #0
        sta     1,y
        rts        
        


cls
        stz     cursor
        stz     cur_line

        lda     #2
        sta     io_ctrl
        lda     #$20
        jsr     fill_screen

        lda     #3
        sta     io_ctrl
        lda     #$14
        jsr     fill_screen
        
        stz     io_ctrl
        jmp     home

home
        pha
        lda     #0
        sta     screen+0
        lda     #$c0
        sta     screen+1
        pla
        rts
        
fill_screen

        phx
        phy

        jsr     home

        ldy     #0
_y      ldx     #0
_x      sta     (screen)
        inc     screen
        bne     _next
        inc     screen+1
_next
        inx
        cpx     #80
        bne     _x
        iny
        cpy     #MAX_LINE+4
        bne     _y

        plx
        ply
        rts

purple
        stz     io_ctrl
        phx
        ldx     #0
_loop   lda     _purple,x
        sta     TEXT_LUT_BG+4*4,x
        inx
        cpx     #4
        bne     _loop
        plx
        rts        
_purple .dword  $3a003a, $600070

            .send
            .endn

