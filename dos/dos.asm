            .cpu    "65c02"

; The kernel presently looks for application in flash to begin with
; a header.  This version was just to get started; revisions to follow.

*           = $a000                     ; Assemble code to run here.
            .text       $f2,$56         ; Signature
            .byte       4               ; 4 blocks (header + 3 for Basic)
            .byte       5               ; mount at $a000
            .word       dos.start       ; Start here
            .word       0               ; version
            .word       0               ; kernel
            .text       "SuperBasic",0  ; Still acting as SuperBASIC's header
            
hello
            ldy     #0
_loop
            lda     _hello,y
            beq     _done
            jsr     display.putchar
            iny
            bra     _loop
_done
            clc
            rts            
_hello      .null   "Hello World!"

            .align      256     ; For the strings.
Strings     .dsection   strings ; All string pointers in the same page.
            .dsection   code
            
*           = $bfff
            .byte       0       ; Fill an entire 8k block.            


            .virtual    $0000   ; Zero page
mmu_ctrl    .byte       ?
io_ctrl     .byte       ?
reserved    .fill       6
mmu         .fill       8
            .dsection   dp
            .dsection   data    ; General data
            .cerror * > $00ff, "Out of dp space."
            .endv

            .virtual    $0200   ; Application memory
            .dsection   pages   ; Aligned segments
            .endv

dos         .namespace            
            .section    code

start
        ; This would be a great place to load fonts,
        ; display a splash screen, etc.  For now,
        ; we'll keep it simple.

          ; If dip1 is off, start SuperBASIC
            stz     io_ctrl
            lda     $d670   ; Read Jr dip switch register.
            eor     #$ff    ; Values are inverted.
            bit     #1
            bne     _shell
            jmp     basic
        
_shell
          ; Start the shell
            jsr     display.init
            jsr     display.cls
            jsr     welcome
            jmp     cmd.start

soft
            jsr     display.init
            lda     #13
            jsr     display.putchar
            lda     #13
            jsr     display.putchar
            jmp     cmd.start
	
welcome
            phy
            ldy     #0
_loop       lda     _msg,y
            beq     _done
            jsr     putc
            iny
            bra     _loop
_done
            ply
            rts        
_msg
            .text   "Foenix F256 by Stefany Allaire", $0a
            .text   "https://c256foenix.com/f256-jr",$0a
            .text   $0a
            .text   "TinyCore MicroKernel", $0a
            .text   "Copyright 2022 Jessie Oberreuter", $0a
            .text   "Gadget@HackwrenchLabs.com",$0a
            .text   "F256 Edition built ", DATE_STR, $0a

            .text   $0a
            .text   "Simple DOS Shell, built ", DATE_STR, $0a
            .text   $0a
            .byte   $0
            
basic
    ; Exit to SuperBASIC
            jmp     kernel.Basic    ; Deprecated call; we'll do better later.

            .send
            .endn        
