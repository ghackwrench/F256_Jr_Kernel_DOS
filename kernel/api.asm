; This file is part of the TinyCore 6502 MicroKernel,
; Copyright 2022 Jessie Oberreuter <joberreu@moselle.com>.
; As with the Linux Kernel Exception to the GPL3, programs
; built to run on the MicroKernel are expected to include
; this file.  Doing so does not effect their license status.

kernel      .namespace

            .virtual    $ff00

NextEvent   .fill   4
ReadData    .fill   4
ReadExt     .fill   4
Yield       .fill   4
Putch       .fill   4   ; deprecated
Basic       .fill   4   ; deprecated
            .fill   4   ; reserved
            .fill   4   ; reserved

BlockDevice .namespace
Read        .fill   4
Write       .fill   4
GetSize     .fill   4
Format      .fill   4
Sync        .fill   4
List        .fill   4
GetName     .fill   4
            .endn

FileSystem  .namespace
List        .fill   4
New         .fill   4
Check       .fill   4
Mount       .fill   4
Unmount     .fill   4
ReadBlock   .fill   4
WriteBlock  .fill   4
GetSize     .fill   4
            .endn

File        .namespace
Open        .fill   4
Read        .fill   4
Write       .fill   4
Close       .fill   4
Rename      .fill   4
Delete      .fill   4
            .endn

Directory   .namespace
Open        .fill   4
Read        .fill   4
Close       .fill   4
            .endn
            
            .fill   4   ; call gate

Config      .namespace
GetIP       .fill   4
SetIP       .fill   4
GetDNS      .fill   4
SetDNS      .fill   4
GetTime     .fill   4
SetTime     .fill   4
GetSysInfo  .fill   4
SetBPS      .fill   4
            .endn

Net         .namespace
InitUDP     .fill   4
SendUDP     .fill   4
RecvUDP     .fill   4
InitTCP     .fill   4
SendTCP     .fill   4
RecvTCP     .fill   4
SendICMP    .fill   4
RecvICMP    .fill   4
            .endn

Draw        .fill   4


            .endv            

event       .namespace

            .struct
LOG         .word   ?
KEY         .word   ?
MOUSE       .word   ?
MIDI        .word   ?
TCP         .word   ?
UDP         .word   ?


directory   .namespace
OPENED      .word   ?
VOLUME      .word   ?
FILE        .word   ?
FREE        .word   ?
EOF         .word   ?
CLOSED      .word   ?
ERROR       .word   ?   ; An error occured; user should close
            .endn

file        .namespace
NOT_FOUND   .word   ?   ; File open (for read) failed.
OPENED      .word   ?
DATA        .word   ?
WROTE       .word   ?
EOF         .word   ?
CLOSED      .word   ?
RENAMED     .word   ?
DELETED     .word   ?
ERROR       .word   ?   ; An error occured; user should close
            .endn

            .ends

event_t     .struct
type        .byte   ?   ; Enum above
buf         .byte   ?   ; page id or zero
ext         .byte   ?   ; 
            .union
            .fill  4
key         .dstruct    kernel.event.key_t
mouse       .dstruct    kernel.event.mouse_t
udp         .dstruct    kernel.event.udp_t
file        .dstruct    kernel.event.fs_t
directory   .dstruct    kernel.event.dir_t
            .endu
            .ends
                 
key_t       .struct
key_cap     .byte   ?
ascii       .byte   ?
            .ends    
            
mouse_t     .struct        
dx          .byte   ?
dy          .byte   ?
dz          .byte   ?
buttons     .byte   ?
            .ends

udp_t       .struct
token       .byte   ?   ; TODO: break out into fields
            .ends

dir_t       .struct
stream      .byte   ?
cookie      .byte   ?
            .union
volume      .dstruct    kernel.event.fs_volume_t
file        .dstruct    kernel.event.fs_dirent_t
free        .dstruct    kernel.event.fs_free_t
            .endu
            .ends

fs_t        .struct
stream      .byte   ?
cookie      .byte   ?
            .union
data        .dstruct    kernel.event.fs_data_t
wrote       .dstruct    kernel.event.fs_wrote_t
            .endu
            .ends
            
fs_data_t   .struct     ; ext contains disk id
requested   .byte   ?   ; Requested number of bytes to read
read        .byte   ?   ; Number of bytes actually read
            .ends

fs_wrote_t  .struct     ; ext contains disk id
requested   .byte   ?   ; Requested number of bytes to read
wrote       .byte   ?   ; Number of bytes actually read
            .ends

fs_volume_t .struct     ; ext contains disk id
len         .byte   ?   ; Length of volname (in buf)
flags       .byte   ?   ; block size, text encoding
            .ends

fs_dirent_t .struct     ; ext contains byte count and modified date
len         .byte   ?
flags       .byte   ?   ; block scale, text encoding, approx size
            .ends

fs_free_t   .struct     ; ext contains byte count and modified date
flags       .byte   ?   ; block scale, text encoding, approx size
            .ends

            .endn

            .virtual    $00f0   ; Arg block
args        .dstruct    args_t
            .endv            

args_t      .struct

          ; Common
event       .word       ?   ; Always: Event pointer; most frequently used call.
src
dest
ptr         .word       ?   ; Always: kernel scratch pointer

          ; Typed
          
            .union

ip          .dstruct    ip_t
file        .dstruct    fs_t
directory   .dstruct    dir_t
recv        .dstruct    recv_t

          ; Drawing arguments
            .struct
x           .byte       ?   ; screen (overlapped with remote)
y           .byte       ?   ; screen (overlapped with remote)
buf         .word       ?   ; block, screen, network
buf2        .word       ?   ; block, screen
buflen      .word       ?   ; Anything with buffers
            .ends

          ; TBD
            .struct
device      .byte       ?   ; Always: device the call is intended for.
            .ends            

            .endu
            .ends

          ; Generic recv
recv_t      .struct
buf         .word       ?
buflen      .byte       ?
ext         .word       ?
extlen      .byte       ?
            .ends

          ; Internet Protocol
ip_t        .struct

socket      .word       ?

            ; Arguments
            .union

            ; Init
            .struct
src_port    .word       ?
dest_port   .word       ?
dest_ip     .fill       4            
            .ends            
            
            ; Send
            .struct
buf         .word       ?
buflen      .byte       ?
ext         .word       ?
extlen      .byte       ?
            .ends

            .endu
            .ends


          ; FileSystem
dir_t       .struct
            .union
open        .dstruct    fs_open_t
read        .dstruct    fs_read_t
close       .dstruct    fs_close_t
            .endu
            .ends            

          ; FileSystem
fs_t        .struct
            .union
open        .dstruct    fs_open_t
read        .dstruct    fs_read_t
write       .dstruct    fs_write_t
close       .dstruct    fs_close_t
rename      .dstruct    fs_rename_t
delete      .dstruct    fs_open_t
            .endu
            .ends            

fs_open_t   .struct
fname       .word       ?   ; Must be first
fname_len   .byte       ?   ; Must be second
            .fill       3   ; Match rename
drive       .byte       ?
cookie      .byte       ?
mode        .byte       ?
READ        = 0
WRITE       = 1
END         = 2
            .ends

fs_read_t   .struct
stream      .byte       ?
buflen      .byte       ?
            .ends
            
fs_write_t  .struct
buf         .word       ?   ; Must be first
buflen      .byte       ?   ; Must be second
stream      .byte       ?
            .ends

fs_close_t  .struct
stream      .byte       ?
            .ends

fs_rename_t .struct
old         .word       ?   ; Must be first
old_len     .byte       ?   ; Must be second
new         .word       ?   ; Address of new name
new_len     .byte       ?   ; Length of new name (must follow the address)
drive       .byte       ?
cookie      .byte       ?
            .ends

fs_delete_t .struct
fname       .word       ?   ; Must be first
fname_len   .byte       ?   ; Must be second
            .fill       3
drive       .byte       ?
cookie      .byte       ?
            .ends


            .endn
