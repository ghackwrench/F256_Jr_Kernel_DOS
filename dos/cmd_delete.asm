            .cpu    "65c02"

delete      .namespace

            .section    code

cmd
          ; This command requires an argument (the file name)
            lda     readline.token_count
            cmp     #2
            sec     ; set error if not.
            bne     _done

          ; Set the drive
            lda     drive
            sta     kernel.args.file.open.drive

          ; Set the filename pointer (it's conveniently aligned)
            lda     readline.tokens+1
            sta     kernel.args.file.open.fname+0
            lda     #>readline.buf
            sta     kernel.args.file.open.fname+1

          ; Set the filename length
            lda     #1  ; Token #1
            jsr     readline.token_length
            sta     kernel.args.file.open.fname_len

          ; Request the delete
            jsr     kernel.File.Delete
            bcs     _error   ; EOM, bad drive, bad filename

_loop
            jsr     kernel.Yield        ; Only b/c we've nothing better to do.
            jsr     kernel.NextEvent
            bcs     _loop

            lda     event.type
            cmp     #kernel.event.file.DELETED
            beq     _done

            lda     event.type
            cmp     #kernel.event.file.ERROR
            beq     _error

            lda     event.type
            cmp     #kernel.event.KEY
            beq     _done
            
            bra     _loop
_done
            jmp     put_cr
_error
        ; The command loop will see that carry is set,
        ; and print the error message.
            rts     

            .send
            .endn
