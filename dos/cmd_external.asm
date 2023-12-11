            .cpu    "65c02"

external    .namespace

            .mkstr      not_executable, "File is not executable."


header_t    .struct
sig_f2      .byte   ?
sig_56      .byte   ?
blocks      .byte   ?
start_slot  .byte   ?
entry       .word   ?
            .fill   4
size        .ends

            .section    data
success     .byte       ?
stream      .byte       ?
remaining   .word       ?
when_done   .word       ?
header      .dstruct    header_t
            .send


            .section    code

cmd
          ; Initialize to "no stream"
            stz     stream

          ; Indicate fail until we know better
            stz     success

          ; Set the drive
            lda     drive
            sta     kernel.args.file.open.drive

          ; Set the filename (conveniently aligned)
            lda     readline.tokens+0
            sta     kernel.args.file.open.fname+0            
            lda     #>readline.buf
            sta     kernel.args.file.open.fname+1

          ; Set the filename length
            lda     #0  ; Token #0
            jsr     readline.token_length
            beq     _handle_not_found
            sta     kernel.args.file.open.fname_len

          ; Set the mode and open
            lda     #kernel.args.file.open.READ
            sta     kernel.args.file.open.mode
            jsr     kernel.File.Open
            bcs     _handle_not_found

          ; Fall through to event loop and load the executable

_event_loop
            jsr     kernel.NextEvent
            bcs     _event_loop

    .if false
            lda     #'>'
            jsr     display.putchar
            lda     event.type
            jsr     display.print_hex
            jsr     put_cr
    .endif

            lda     event.type

            cmp     #kernel.event.key.PRESSED
            beq     _handle_check_escape

            cmp     #kernel.event.file.NOT_FOUND
            beq     _handle_not_found
            cmp     #kernel.event.file.ERROR
            beq     _handle_not_found

            cmp     #kernel.event.file.OPENED
            beq     _handle_opened
            cmp     #kernel.event.file.DATA
            beq     _handle_data_read
            cmp     #kernel.event.file.CLOSED
            beq     _handle_file_closed
            cmp     #kernel.event.file.EOF
            beq     _handle_eof

            bra     _event_loop


_handle_not_found
            sec
            rts


_handle_check_escape
            lda     event.key.raw
            cmp     #ESC
            bne     _event_loop
            jmp     _close_file


_handle_file_closed
            lda     success
            beq     _exit_good
            jmp     _start_program
_exit_good
            clc
            rts


_handle_opened
          ; Read file header
            lda     event.file.stream
            sta     stream

            lda     #<header
            sta     kernel.args.buf
            lda     #>header
            sta     kernel.args.buf+1

            lda     #<_handle_header_read
            sta     when_done
            lda     #>_handle_header_read
            sta     when_done+1

            lda     #<header_t.size
            sta     remaining
            stz     remaining+1

            jmp     _start_read


_handle_data_read
          ; Some data has been read from file
    .if false
            lda     #'-'
            jsr     putc
            lda     event.file.data.read
            jsr     display.print_hex
            jsr     put_cr
    .endif

            lda     event.file.data.read
            sta     kernel.args.buflen
            
            jsr     kernel.ReadData

          ; Advance destination pointer
            clc
            lda     kernel.args.buf
            adc     kernel.args.buflen
            sta     kernel.args.buf
            bcc     _skip_inc
            inc     kernel.args.buf+1
_skip_inc

          ; Decrement remaining count
            sec
            lda     remaining
            sbc     kernel.args.buflen
            sta     remaining
            lda     remaining+1
            sbc     #0
            sta     remaining+1

          ; Continue read if not all bytes read
            lda     remaining
            ora     remaining+1
            beq     _handle_eof
            jmp     _start_read

_handle_eof
          ; Reading done, continue
            jmp     (when_done)


_handle_header_read
          ; Header has been read, does the magic number match?
            lda     header.sig_f2
            cmp     #$f2
            bne     _not_executable
            lda     header.sig_56
            cmp     #$56
            beq     _is_executable

          ; Not executable, close file
_not_executable
            lda     #not_executable_str
            jsr     puts_cr
            bra     _close_file
_is_executable
          ; File is executable, load rest into memory
            lda     #header_t.size
            sta     kernel.args.buf
            lda     header.start_slot
            asl     a
            asl     a
            asl     a
            asl     a
            asl     a
            sta     kernel.args.buf+1

            lda     header.blocks
            asl     a
            asl     a
            asl     a
            asl     a
            asl     a
            stz     remaining
            sta     remaining+1

            lda     #<_handle_exe_read
            sta     when_done
            lda     #>_handle_exe_read
            sta     when_done+1

            jmp     _start_read


_handle_exe_read
            lda     #$ff
            sta     success
            
            ; fall through to _close_file
_close_file
            lda     stream
            bne     _close_good
            clc
            rts
_close_good            
            sta     kernel.args.file.close.stream 
            jsr     kernel.File.Close

            jmp     _event_loop


_start_program
        .if false
            lda     #'!'
            jsr     putc
            jsr     put_cr
        .endif


          ; Run program
            jsr     _start_enter
            bcc     _exited_reinit

          ; Carry set, reset machine
            stz     $01
            lda     #$DE
            sta     $D6A2
            lda     #$AD
            sta     $D6A3
            lda     #$80
            sta     $D6A0
            stz     $D6A0
_spin       bra     _spin   ; wait for reset

_exited_reinit
          ; Reinitialize essential DOS functionality.
            jsr     kernel.Display.Reset
            jsr     display.init
            jsr     display.cls

          ; Tell the event call where to dump events.
            lda     #<event
            sta     kernel.args.events+0
            lda     #>event
            sta     kernel.args.events+1

            clc
            rts
_start_enter
            jmp     (header.entry)


_start_read
    .if false
            lda     #'+'
            jsr     putc
            lda     remaining+1
            jsr     display.print_hex
            lda     remaining
            jsr     display.print_hex
            jsr     put_cr
    .endif

          ; Set read length, max 128 bytes at a time
            lda     remaining+1
            bne     _limit_read
            lda     remaining
            bpl     _read_len_good
_limit_read
            lda     #128
_read_len_good
            sta     kernel.args.file.read.buflen

          ; Set stream id and start read
            lda     stream
            sta     kernel.args.file.read.stream

            jsr     kernel.File.Read
            bcs     _close_file

            jmp     _event_loop


            .send
            .endn

