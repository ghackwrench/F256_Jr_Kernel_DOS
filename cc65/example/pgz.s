        .segment    "HEADER"
        .import     __STARTUP_LOAD__, __CODE_LOAD__, __PGZ_END_LOAD__

        LOAD = __CODE_LOAD__
        SIZE = __PGZ_END_LOAD__ - __CODE_LOAD__
        EXEC  = __STARTUP_LOAD__

        .byte   'Z'         ; signature
        .word   LOAD        ; addr LSW
        .byte   0           ; addr MSB
        .word   SIZE        ; size LSW
        .byte   0           ; size MSB

        .segment    "END"       ; Defined for heap computation

        .segment    "PGZ_END"
        .word   EXEC        ; exec addr LSW
        .byte   0           ; exec addr MSB
        .word   0           ; size LSW
        .byte   0           ; size MSB
