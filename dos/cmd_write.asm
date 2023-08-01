            .cpu    "65c02"

write       .namespace

            .mkstr      enter,  "Enter message.  A line containing a single period ends input."

            .section    data
stream      .byte       ?
            .send

            .section    code

cmd
          ; This command requires an argument (the file name)
            lda     readline.token_count
            cmp     #2
            sec     ; set error if not.
            bne     _done

          ; Set the drive
            lda     #1  ; Token #1
            jsr     readline.parse_drive
            sta     kernel.args.file.open.drive

          ; Set the filename pointer (it's conveniently aligned)
            lda     readline.tokens+1
            sta     kernel.args.file.open.fname+0
            lda     #>readline.buf
            sta     kernel.args.file.open.fname+1

          ; Set the filename length
            lda     #1  ; Token #1
            jsr     readline.token_length
            tay
            beq     _error
            sta     kernel.args.file.open.fname_len

          ; Open the file for create/overwrite
            lda     #kernel.args.file.open.WRITE
            sta     kernel.args.file.open.mode
            jsr     kernel.File.Open
            bcs     _error   ; EOM, bad mode, bad drive, zero length filename

          ; Save the stream.  In other examples, we just grab it from
          ; the previous event, but in this case, the previous event will
          ; generally have been a key event rather than a file event.
            sta     stream

_loop
            jsr     kernel.Yield        ; Only b/c we've nothing better to do.
            jsr     kernel.NextEvent
            bcs     _loop

            lda     event.type
            cmp     #kernel.event.file.CLOSED
            beq     _done

            jsr     _dispatch
            bra     _loop
_done
            jmp     put_cr
_error
            sec
            rts     

_dispatch
            cmp     #kernel.event.file.OPENED
            beq     _begin
            cmp     #kernel.event.file.WROTE
            beq     _input
            cmp     #kernel.event.file.ERROR
            beq     _eof
            cmp     #kernel.event.file.EOF
            beq     _eof
            rts

_begin
          ; Print the instructions and fall-through to input.
            lda     #enter_str
            jsr     puts_cr

_input
        ; Read and append lines of text until a line with just a period. 

          ; Get a line of text
            jsr     readline.read

          ; Append the CR
            ldy     readline.length
            sta     readline.buf,y
            iny

          ; Test for end-of-message
            cpy     #2
            bne     _write
            lda     readline.buf
            cmp     #'.'
            bne     _write
            bra     _eof

_write
    ; IN: buf -> text, Y = length

          ; Set the steram
            lda     stream
            sta     kernel.args.file.write.stream

          ; Set the buffer pointer
            lda     #<readline.buf
            sta     kernel.args.file.write.buf+0
            lda     #>readline.buf
            sta     kernel.args.file.write.buf+1

          ; Set the buffer length
            sty     kernel.args.file.write.buflen

          ; Call write
            jsr     kernel.File.Write
            bcs     _eof    ; Close on error
            rts

_eof
            lda     stream
            sta     kernel.args.file.close.stream
            jmp     kernel.File.Close


            .send
            .endn
