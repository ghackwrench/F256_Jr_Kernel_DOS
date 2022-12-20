            .cpu    "65c02"

rename      .namespace

            .section    code

cmd
          ; This command requires two arguments (old name, new name)
            lda     readline.token_count
            cmp     #3
            sec     ; set error if not.
            bne     _done

          ; Set the drive
            lda     drive
            sta     kernel.args.file.open.drive

          ; Set the old name pointer (it's conveniently aligned)
            lda     readline.tokens+1
            sta     kernel.args.file.rename.old+0
            lda     #>readline.buf
            sta     kernel.args.file.rename.old+1

          ; Set the old name length
            lda     #1  ; Token #1
            jsr     readline.token_length
            sta     kernel.args.file.rename.old_len

          ; Set the new name pointer (it's conveniently aligned)
            lda     readline.tokens+2
            sta     kernel.args.file.rename.new+0
            lda     #>readline.buf
            sta     kernel.args.file.rename.new+1

          ; Set the new name length
            lda     #2  ; Token #2
            jsr     readline.token_length
            sta     kernel.args.file.rename.new_len

          ; Request the rename
            jsr     kernel.File.Rename
            bcs     _error   ; EOM, bad drive, bad filename

_loop
            jsr     kernel.Yield        ; Only b/c we've nothing better to do.
            jsr     kernel.NextEvent
            bcs     _loop

            lda     event.type
            cmp     #kernel.event.file.RENAMED
            beq     _done

            lda     event.type
            cmp     #kernel.event.file.ERROR
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
