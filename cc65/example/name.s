        .segment    "HEADER"
        .import     __STARTUP_LOAD__, __END_LOAD__

        EXEC  = __STARTUP_LOAD__
        SLOT  = __STARTUP_LOAD__ >> 13
        COUNT = __END_LOAD__ >> 13   ; Assumes code starts at $2000.

        .byte   $f2,$56     ; signature
        .byte   <COUNT      ; block count
        .byte   <SLOT       ; start slot
        .word   EXEC        ; exec addr
        .word   0           ; version
        .word   0           ; kernel
        .asciiz "hello"     ; name

        .segment    "END"
