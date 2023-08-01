            .cpu    "65c02"

keys        .namespace

            .include    "kernel/keys.asm"
            .mkstr      desc,  "This program shows the held status of keys.  Press <ENTER> to quite."

            .section    code

cmd
            lda     #desc_str
            jsr     puts_cr
            jsr     display.cursor_off
            lda     #2
            sta     io_ctrl

_loop
            jsr     kernel.Yield        ; Only b/c we've nothing better to do.
            jsr     kernel.NextEvent
            bcs     _loop

            lda     event.type
            cmp     #kernel.event.key.PRESSED
            beq     _pressed
            cmp     #kernel.event.key.RELEASED
            beq     _released
            cmp     #kernel.event.JOYSTICK
            beq     _joy

            bra     _loop

_joy
            ldx     #0
            lda     event.joystick.joy0
            jsr     display.print_hex
            lda     event.joystick.joy1
            jsr     display.print_hex
            bra     _loop

_released
            lda     #' '
            bra     _show

_pressed
            ldy     event.key.ascii
            cpy     #13
            beq     _done

            lda     #'X'
            bit     event.key.flags
            bmi     _show
            lda     event.key.ascii
_show
            ldy     event.key.raw            
            sta     (display.screen),y
            bra     _loop

_done
            jsr     display.cursor_on
            clc
            rts


            .send
            .endn
