            .cpu    "65c02"

wifi        .namespace

            .section    dp
state       .byte       ?
reset       .byte       ?
            .send            

            .section    pages
socket      .fill       256
buffer      .fill       256
            .send            

            .section    code

cmd
          ; This command requires two arguments (old name, new name)
            lda     readline.token_count
            cmp     #3
            sec     ; set error if not.
            bne     _error

          ; Kick the IP stack (working around a bug...)
            jsr     net_init

          ; Init the conversation state.
            stz     state
            stz     reset

          ; Start the connection.
            jsr     tcp_open

_yield
            jsr     kernel.Yield
_loop
            jsr     kernel.NextEvent
            bcs     _yield

            lda     event.type

            cmp     #kernel.event.net.TCP
            beq     _tcp

            cmp     #kernel.event.key.PRESSED
            beq     _kbd
        
            bra     _loop

_tcp
            jsr     tcp_recv
            bcc     _loop
            clc
            rts

_kbd
            lda     event.key.ascii
            cmp     #3
            bne     _loop

_error
        ; The command loop will see that carry is set,
        ; and print the error message.
            sec
            rts     

tcp_open
            stz     kernel.args.net.socket+0
            lda     #>socket
            sta     kernel.args.net.socket+1
            lda     #255
            sta     kernel.args.buflen
            
            ldy     #0
_copy       lda     _args,y
            sta     kernel.args.net,y
            iny
            cpy     #8
            bne     _copy
            jmp     kernel.Net.TCP.Open
_args       .word   7777,7777
            .byte   192,168,240,1


tcp_recv
            stz     kernel.args.net.socket+0
            lda     #>socket
            sta     kernel.args.net.socket+1
    
            lda     #<buffer
            sta     kernel.args.net.buf+0
            lda     #>buffer
            sta     kernel.args.net.buf+1
            lda     #$ff
            sta     kernel.args.net.buflen
    
            jsr     kernel.Net.Match
            bcs     _out
    
            jsr     kernel.Net.TCP.Recv
            bcs     _out

            lda     kernel.args.net.accepted
            beq     _okay

            ldy     #0
_loop       lda     (kernel.args.net.buf),y
            pha
            jsr     putc
            pla
            iny
            cpy     kernel.args.net.accepted
            bne     _loop
            cmp     #'>'
            bne     _okay

            ldx     state
            inc     state
            inc     state
            jsr     _call
_okay
            lda     reset
            bne     _out
            clc
            rts
_out    
            sec
            rts
_call
            jmp     (_cmd,x)
_cmd
            .word   tcp_send_ssid_cmd
            .word   tcp_send_passwd_cmd
            .word   tcp_send_save_cmd
            .word   tcp_send_reset_cmd
            .word   _dummy
_dummy      
            inc     reset
            rts            

tcp_send_ssid_cmd

          ; Send the command.
            lda     #<_text
            sta     kernel.args.net.buf+0
            lda     #>_text
            sta     kernel.args.net.buf+1
            lda     #_length
            sta     kernel.args.net.buflen
            jsr     tcp_send

          ; Send the argument.
            lda     #1
            jmp    send_token
            
_text       .text   "set ssid "
_length     =       * - _text            

tcp_send_passwd_cmd

          ; Send the command.
            lda     #<_text
            sta     kernel.args.net.buf+0
            lda     #>_text
            sta     kernel.args.net.buf+1
            lda     #_length
            sta     kernel.args.net.buflen
            jsr     tcp_send

          ; Send the argument.
            lda     #2
            jmp     send_token

_text       .text   "set password "
_length     =       * - _text            

tcp_send_save_cmd

          ; Send the command.
            lda     #<_text
            sta     kernel.args.net.buf+0
            lda     #>_text
            sta     kernel.args.net.buf+1
            lda     #_length
            sta     kernel.args.net.buflen
            jmp     tcp_send

_text       .text   "save",10
_length     =       * - _text            

tcp_send_reset_cmd

          ; Exit when this is ack'ed.
            inc     reset

          ; Send the command.
            lda     #<_text
            sta     kernel.args.net.buf+0
            lda     #>_text
            sta     kernel.args.net.buf+1
            lda     #_length
            sta     kernel.args.net.buflen
            jmp     tcp_send

_text       .text   "reset",10
_length     =       * - _text            


send_token

          ; Set the token's length.
            pha
            jsr     readline.token_length
            sta     kernel.args.net.buflen
            pla

          ; Send the token.
            tax
            lda     readline.tokens,x
            sta     kernel.args.net.buf+0
            lda     #>readline.buf
            sta     kernel.args.net.buf+1
            jsr     tcp_send

          ; Send an LF.
            lda     #<_lf
            sta     kernel.args.net.buf+0
            lda     #>_lf
            sta     kernel.args.net.buf+1
            lda     #1
            sta     kernel.args.net.buflen
            bra     tcp_send

_lf         .byte   10                        


tcp_send

          ; Print the buffer.
            ldy     #0
_loop       lda     (kernel.args.net.buf),y
            jsr     putc
            iny
            cpy     kernel.args.net.buflen
            bne     _loop

          ; Send it.
            stz     kernel.args.net.socket+0
            lda     #>socket
            sta     kernel.args.net.socket+1
            jmp     kernel.Net.TCP.Send


net_init
    ; Send a dummy packet to kick the networking.
    ; Kernel or IRQ controller issue somewhere.

      ; Socket
        lda     #<socket
        sta     kernel.args.net.socket+0
        lda     #>socket
        sta     kernel.args.net.socket+1

        ; Ports
        lda     #<12345 ; Big Endian
        sta     kernel.args.net.src_port+0
        sta     kernel.args.net.dest_port+0
        lda     #>12345
        sta     kernel.args.net.src_port+1
        sta     kernel.args.net.dest_port+1

        ; Dest IP
        lda     #192
        sta     kernel.args.net.dest_ip+0
        lda     #168
        sta     kernel.args.net.dest_ip+1
        lda     #240
        sta     kernel.args.net.dest_ip+2
        lda     #1
        sta     kernel.args.net.dest_ip+3

        jsr     kernel.Net.UDP.Init

        lda     #<_lf
        sta     kernel.args.net.buf+0
        lda     #>_lf
        sta     kernel.args.net.buf+1
        lda     #1
        sta     kernel.args.net.buflen

        jmp     kernel.Net.UDP.Send
        
_lf     .byte   10

            .send
            .endn
