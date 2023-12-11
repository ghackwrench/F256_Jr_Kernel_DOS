            .cpu    "65c02"

readline    .namespace

OFFSET = 3
MAX = 78-OFFSET
MAX_TOKENS = 8

            .section    dp
line        .word       ?
            .send
             
            .section    data
cursor      .byte       ?
length      .byte       ?
tokens      .fill       MAX_TOKENS
token_count .byte       ?   ; Token count
            .send

            .section    kupdata
buf         .fill       128 ; Only need 80, must be page aligned
argv        .fill       (readline.MAX_TOKENS+1)*2
            .send

            .section    code

read            
            stz     cursor
            stz     length
_loop
            jsr     refresh
_event
            jsr     kernel.NextEvent
            bcs     _event

            lda     event.type
            cmp     #kernel.event.key.PRESSED
            beq     _kbd
            bra     _event
            
_kbd
            lda     event.key.ascii
            cmp     #13
            beq     _done
            cmp     #32
            bcc     _ctrl
            jsr     insert
            bra     _loop
_ctrl
            jsr     ctrl
            bra     _loop            
_done
            jmp     putc       

ctrl
            cmp     #'B'-64
            beq     left
            cmp     #'F'-64
            beq     right
            cmp     #'A'-64
            beq     home
            cmp     #'E'-64
            beq     end
            cmp     #'H'-64
            beq     back
            cmp     #'D'-64
            beq     del
            cmp     #'K'-64
            beq     kill
            rts

kill
            lda     cursor
            cmp     length
            beq     _done
            jsr     del
            jsr     refresh
            bra     kill
_done       rts            

left
            lda     cursor
            beq     _done
            dec     cursor
_done            
            rts
right
            lda     cursor
            cmp     length
            bcs     _done
            inc     cursor
_done            
            rts                 
home
            stz     cursor
            rts
end
            lda     length
            sta     cursor
            rts
del
            ldy     cursor
            cpy     length
            bcs     _done
_loop
            lda     buf+1,y
            sta     buf,y
            iny            
            cpy     length
            bne     _loop
            dec     length
_done            
            rts

back
            ldy     cursor
            beq     _done
            cpy     length
            beq     _simple
_loop            
            lda     buf,y
            sta     buf-1,y
            iny
            cpy     length
            bne     _loop
_simple
            dec     cursor
            dec     length
            rts            
_done
            rts

insert
            ldy     length
            cpy     #MAX
            beq     _done
            
            ldy     cursor
            cpy     length
            beq     _insert

            pha
            ldy     length     
_loop
            lda     buf-1,y
            sta     buf,y
            dey
            cpy     cursor
            bne     _loop
            pla

_insert
            sta     buf,y
            inc     cursor
            inc     length
_done
            jmp     refresh

refresh
            phy

            jsr     display.cursor_off

            lda     display.screen+0
            sta     line+0
            lda     display.screen+1
            sta     line+1

            ldy     #line
            lda     #OFFSET
            jsr     display.add

            ldy     #0
_loop
            cpy     length
            beq     _done
            lda     buf,y
            sta     (line),y
            iny
            bra     _loop
_done
            lda     #$20
            sta     (line),y

            clc
            lda     cursor
            adc     #OFFSET
            sta     display.cursor
            jsr     display.cursor_on

            ply
            rts

populate_arguments:
          ; Populate argv array
            ldx     #0
            ldy     #0
_copy_token
            lda     readline.tokens,y
            sta     argv,x
            inx
            lda     #>readline.buf
            sta     argv,x
            inx
            iny
            cpy     readline.token_count
            bne     _copy_token

          ; null terminate argv array
            stz     argv,x
            stz     argv+1,x

          ; Set ext and extlen to argv and argc
            lda     #<argv
            sta     kernel.args.ext
            lda     #>argv
            sta     kernel.args.ext+1
            lda     readline.token_count
            asl     a
            sta     kernel.args.extlen

            rts

tokenize
            ldx     #0      ; Token count
            ldy     #0      ; Start of line
_loop
            jsr     skip_white
            cpy     length
            bcs     _done

            tya
            sta     tokens,x
            inx

            jsr     skip_token
            cpy     length
            bcs     _done

            lda     #0
            sta     buf,y
            iny
            
            cpx     #MAX_TOKENS
            bne     _loop
_done
            lda     #0
            sta     buf,y
            stx     token_count
            rts            

skip_white
            cpy     length
            bcs     _done
            lda     buf,y
            cmp     #' '
            bne     _done
            iny
            bra     skip_white
_done
            rts            

skip_token
            cpy     length
            bcs     _done
            lda     buf,y
            cmp     #' '
            beq     _done
            iny
            bra     skip_token
_done
            rts            

token_length
    ; IN: A = token#
    ; OUT: A=token length
    
            phx
            phy
            
            cmp     token_count
            bcs     _out

            tax
            ldy     tokens,x

            ldx     #0
_loop       lda     buf,y            
            beq     _done
            inx
            iny
            bra     _loop
_done
            txa
_out                        
            ply
            plx
            rts
            
parse_drive
	; IN: A = token#
			tax

          ; Make sure we have an argument
            lda     token_count
            cmp     #2
            bcc     _default
            
          ; Make sure it's at least 2 characters
            txa
            jsr     token_length
            cmp     #2
            bcc     _default
            
          ; Consider only <drive><colon> prefixen
            ldy     readline.tokens+1
            lda     buf+1,y
            cmp     #':'
            bne     _default
            
          ; Consider the first character a drive;
          ; other layers can check if it's valid
            lda     buf,y
            and     #7
            
          ; Remove the drive spec from the token
            inc     tokens+1
            inc     tokens+1
            
            rts
            
_default
            lda     drive   ; Return the default 
            rts

            .send
            .endn
            
