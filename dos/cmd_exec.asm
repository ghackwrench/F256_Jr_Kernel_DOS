            .cpu    "65c02"

exec        .namespace

            .section    dp
addr        .word       ?
            .send

            .section    code

cmd
          ; This command requires an argument (the file name)
            lda     readline.token_count
            cmp     #2
            sec     ; set error if not.
            bne     _error

          ; The first character of the arg should be '$'
            ldy     readline.tokens+1
            lda     readline.buf,y
            cmp     #'$'
            sec
            bne     _error
            
          ; The arg should be at least four bytes long
            lda     #1  ; token #1
            jsr     readline.token_length
            cmp     #4
            bcc     _error    

          ; X = length of address hex
            tax
            dex
            
          ; parse the arg
            stz     addr+0
            stz     addr+1
            ldy     readline.tokens+1
            iny     ; skip the '$'
_loop       jsr     shift_addr
            lda     readline.buf,y
            iny
            jsr     atod
            bcs     _error
            ora     addr+0
            sta     addr+0
            dex
            bne     _loop                        

          ; call the program
            jsr     _start
            
          ; Soft-restart DOS
            pla
            pla
            jmp     dos.soft

_start
            jmp     (addr)

_error
            sec
            rts

shift_addr
            asl     addr+0
            rol     addr+1

            asl     addr+0
            rol     addr+1

            asl     addr+0
            rol     addr+1

            asl     addr+0
            rol     addr+1

            rts

atod
            phx
            phy
            ldy     #0
_loop
            sec
            ldx     _src,y
            beq     _done
            cmp     _src,y
            beq     _found
            iny
            bra     _loop
_found      
            lda     _map,y
            clc
_done
            ply
            plx
            rts
_src        
            .null   "0123456789abcdefABCDEF"
_map
            .byte   0,1,2,3,4,5,6,7,8,9
            .byte   10,11,12,13,14,15,16            
            .byte   10,11,12,13,14,15,16            
            

            .send
            .endn
            
