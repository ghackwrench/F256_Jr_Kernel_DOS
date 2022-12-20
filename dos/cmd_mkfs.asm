            .cpu    "65c02"

mkfs        .namespace

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
            sta     kernel.args.fs.mkfs.label+0
            lda     #>readline.buf
            sta     kernel.args.fs.mkfs.label+1

          ; Set the filename length
            lda     #1  ; Token #1
            jsr     readline.token_length
            sta     kernel.args.fs.mkfs.label_len

          ; Request the delete
            jsr     kernel.FileSystem.MkFS
            bcs     _error   ; EOM, bad drive, bad filename

_loop
            jsr     kernel.Yield        ; Only b/c we've nothing better to do.
            jsr     kernel.NextEvent
            bcs     _loop

            lda     event.type
            cmp     #kernel.event.fs.CREATED
            beq     _done

            lda     event.type
            cmp     #kernel.event.fs.ERROR
            beq     _error

            lda     event.type
            cmp     #kernel.event.key.PRESSED
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
