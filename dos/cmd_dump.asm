            .cpu    "65c02"

dump        .namespace

            .section    dp
count       .byte       ?
print_fn    .word       ?
            .send

WIDTH = 16  ; hex dump width / requested read size.

            .section    code

cmd
            lda     #WIDTH
            sta     count

            lda     #<print
            sta     print_fn+0
            lda     #>print
            sta     print_fn+1

            lda     #WIDTH
            ldx     #print_fn
            jmp     reader.read_file
            
print
            jsr     print_hex
            jsr     print_space
            dec     count
            bne     _done
            jsr     put_cr
            lda     #WIDTH
            sta     count
_done
            rts

print_space
            lda     #' ' 
            jmp     putc

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

            .send
            .endn
            
