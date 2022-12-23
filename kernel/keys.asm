; This file is part of the TinyCore 6502 MicroKernel,
; Copyright 2022 Jessie Oberreuter <joberreu@moselle.com>.
; As with the Linux Kernel Exception to the GPL3, programs
; built to run on the MicroKernel are expected to include
; this file.  Doing so does not effect their license status.

        .virtual 0
LSHIFT  .byte   ?
RSHIFT  .byte   ?
LCTRL   .byte   ?
RCTRL   .byte   ?
LALT    .byte   ?
RALT    .byte   ?
LMETA   .byte   ?
RMETA   .byte   ?
CAPS    .byte   ?
        .endv

        .virtual    $80        
POWER   .byte   ?
F1      .byte   ?
F2      .byte   ?
F3      .byte   ?
F4      .byte   ?
F5      .byte   ?
F6      .byte   ?
F7      .byte   ?
F8      .byte   ?
F9      .byte   ?
F10     .byte   ?
F11     .byte   ?
F12     .byte   ?
F13     .byte   ?
F14     .byte   ?
F15     .byte   ?
F16     .byte   ?
DEL     .byte   ?
BKSP    .byte   ?
TAB     .byte   ?
ENTER   .byte   ?
ESC     .byte   ?
        .endv

        .virtual    $a0
K0      .byte   ?
K1      .byte   ?
K2      .byte   ?
K3      .byte   ?
K4      .byte   ?
K5      .byte   ?
K6      .byte   ?
K7      .byte   ?
K8      .byte   ?
K9      .byte   ?
KPLUS   .byte   ?
KMINUS  .byte   ?
KTIMES  .byte   ?
KDIV    .byte   ?
KPOINT  .byte   ?
KENTER  .byte   ?
NUM     .byte   ?

PUP     .byte   ?
PDN     .byte   ?
HOME    .byte   ?
END     .byte   ?
INS     .byte   ?
UP      .byte   ?
DOWN    .byte   ?
LEFT    .byte   ?
RIGHT   .byte   ?
SCROLL  .byte   ?
SYSREQ  .byte   ?
BREAK   .byte   ?


SLEEP   .byte   ?
WAKE    .byte   ?
PRTSCR  .byte   ?
MENU    .byte   ?
PAUSE   .byte   ?

        .endv

