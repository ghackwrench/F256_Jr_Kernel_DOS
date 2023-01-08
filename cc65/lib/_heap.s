        .import         __END_LOAD__, __HIMEM__

        HEAP = (__END_LOAD__ + $1fff) & $E000
        .global         __heaporg
        .global         __heapptr
        .global         __heapend
        .global         __heapfirst
        .global         __heaplast

.data

__heaporg:
        .word   HEAP
__heapptr:
        .word   HEAP
__heapend:
        .word   __HIMEM__
__heapfirst:
        .word   0
__heaplast:
        .word   0


