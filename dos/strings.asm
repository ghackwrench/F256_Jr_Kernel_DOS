            .cpu    "65c02"

mkstr       .segment   label, data
            .section    code
\1_msg      .null       \2
            .send
            .section    strings
\1_ptr      .word       \1_msg
            .send
\1_str      = <\1_ptr
            .endm

            .section    code
puts        jmp     strings.puts
puts_cr     jmp     strings.puts_cr
            .send

strings     .namespace

            .section    dp
str         .word       ?
            .send            

            .section    code

puts_cr
            jsr     puts
            jmp     put_cr

puts_zero
        ; Input - XA string            
            phx
            phy

            stx     strings.str+0
            sta     strings.str+1

            ldy     #0
_loop
            lda     (strings.str),y
            beq     _done
            jsr     putc
            iny
            bra     _loop
_done
            ply
            plx
            clc
            rts            

puts
            phy

            tay
            ldx     Strings+0,y
            lda     Strings+1,y
            jsr     puts_zero
            
            ply
            clc
            rts            
            
            .send

            .endn
