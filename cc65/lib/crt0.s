;
; Start-up code for cc65 (Foenix F256 Jr)
;

        .export         _exit, _event, _args
        .export         __STARTUP__ : absolute = 1      ; Mark as start-up

        .import         initlib, donelib
        .import         zerobss
        .import         copydata
        .import         _main
        .import         __STACKSTART__   ; From c256.cfg

        .include        "zeropage.inc"

        .PC02

        .segment        "STARTUP"
Start:  

      ; Stash the original stack pointer so we can "return"
      ; to DOS (or whatever) from anywhere.
        tsx
        stx     spsave

      ; Run the rest of the init code from the ONCE segment;
      ; the ONCE segment may then be merged into the heap.
        jsr     init

      ; Push the command-line arguments, and call main().
        jsr     _main

_exit:    

      ; Disable the cursor
        stz     $1
        stz     $d010

      ; Restore the original stack pointer
        ldx     spsave
        txs 

      ; Run cleanup.
        jsr     donelib

      ; Return to the shell
        rts

        .segment    "ZEROPAGE" : zeropage
_event: .res    7

        .segment    "KERNEL_ARGS" : zeropage
_args:  .res    16

        .segment    "INIT"
spsave: .res    1

        .segment    "ONCE"

init:

      ; Set up the stack.
        lda     #<__STACKSTART__
        ldx     #>__STACKSTART__
        sta     sp
        stx     sp+1            ; Set argument stack ptr

      ; Call the module constructors.
        jsr     initlib
        
      ; Zero the BSS
        jsr     zerobss

      ; Initialze statically initialized variables.
        jsr     copydata

      ; Initialize the kernel interface.
        lda     #<_event
        sta     _args+0
        stz     _args+1

        rts
        
