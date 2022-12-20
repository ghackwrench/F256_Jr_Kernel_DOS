            .cpu    "65c02"

dir         .namespace

            .mkstr      tab,    "    "
            .mkstr      dir,    "  Directory of "
            .mkstr      free,   "  Blocks Free."

            .section    data
stop        .byte       ?
            .send            

            .section    code

cmd
          ; Initialize the stop flag
            stz     stop

          ; Set the drive for open
            lda     drive
            sta     kernel.args.directory.open.drive

          ; No path argument yet :).
            stz     kernel.args.directory.open.fname_len

          ; Open
            jsr     kernel.Directory.Open
            bcc     _loop
            
          ; Invalid device or out-of-memory.
            rts     ; Return with carry set to indicate error

_loop
            jsr     kernel.Yield        ; Polite, not actually needed.
            jsr     kernel.NextEvent
            bcs     _loop
            lda     event.type  

            cmp     #kernel.event.directory.CLOSED
            beq     _closed

            jsr     _dispatch
            bra     _loop
            
_closed
            clc
            jmp     put_cr

_dispatch
            cmp     #kernel.event.directory.OPENED
            beq     _read
            cmp     #kernel.event.directory.VOLUME
            beq     _volume
            cmp     #kernel.event.directory.FILE
            beq     _file
            cmp     #kernel.event.directory.FREE
            beq     _free
            cmp     #kernel.event.directory.EOF
            beq     _eof
            cmp     #kernel.event.directory.ERROR
            beq     _eof
            cmp     #kernel.event.key.PRESSED
            beq     _key

            rts

_key
          ; Request early termination.
            lda     event.key.ascii
            sta     stop
            rts            
_read
            lda     event.directory.stream
            sta     kernel.args.directory.read.stream
            jmp     kernel.Directory.Read
_volume

          ; Read volume.len bytes into buf.
            lda     event.directory.volume.len
            jsr     read_data

          ; Print the volume name.
            lda     #dir_str
            jsr     puts
            lda     #$22
            jsr     putc
            jsr     print_buf
            lda     #$22
            jsr     putc
            jsr     put_cr

            bra     _read
_file
          ; If an early stop has been requested, close.
            lda     stop
            bne     _eof

          ; Read and print the extended file data
            jsr     read_ext
            lda     #tab_str
            jsr     puts
            jsr     print_ext

          ; Tab
            lda     #tab_str
            jsr     puts

          ; Read and print the file name
            lda     event.directory.file.len
            jsr     read_data
            jsr     print_buf
            jsr     put_cr

            bra     _read
_free
        ; Read and print the number of blocks free.
        ; This should eventually adapt to the blocksize
        ; as defined in the primary event data.
        
            jsr     read_ext

            lda     #' '
            jsr     putc
            lda     #' '
            jsr     putc

            jsr     print_ext
            lda     #free_str
            jsr     puts
            bra     _eof
_eof
            lda     event.directory.stream
            sta     kernel.args.directory.close.stream
            jmp     kernel.Directory.Close
            
read_data
    ; IN: A = # of bytes to read
    
            sta     kernel.args.recv.buflen

            lda     #<buf
            sta     kernel.args.recv.buf+0
            lda     #>buf
            sta     kernel.args.recv.buf+1

            jsr     kernel.ReadData

          ; Terminate the string with a nil.
            lda     #0
            ldy     kernel.args.recv.buflen
            sta     buf,y

            rts

print_buf
            phy
            ldy     #0
_loop
            lda     buf,y
            beq     _done
            jsr     putc
            iny
            bra     _loop
_done
            ply
            rts                


read_ext
            lda     #<buf
            sta     kernel.args.recv.buf+0
            lda     #>buf
            sta     kernel.args.recv.buf+1
            lda     #2
            sta     kernel.args.recv.buflen

            jmp     kernel.ReadExt

print_ext
    ; TODO: overlay the appropriate struct and read the members.

            lda     buf+1
            jsr     print_hex

            lda     buf+0
            jsr     print_hex

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

            .send
            .endn

