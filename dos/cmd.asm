            .cpu    "65c02"

            ; Globals
            
            .section    pages
buf         .fill       256     ; Used to fetch data from the kernel.
            .send

            .section    data
drive       .byte       ?                       ; Current selected (logical) drive #
event       .dstruct    kernel.event.event_t    ; Event data copied from the kernel
            .send

cmd         .namespace
        
            .mkstr  devlist,    "Registered File-System devices: "
            .mkstr  nolist,     "No drives found."
            .mkstr  unknown,    "Unknown command."
            .mkstr  failed,     "Command failed."
            .mkstr  help,       "Enter 'help' for help, 'about' for information about this software."
            .mkstr  bad_drive,  "Drive number must be in [0..7]."
            .mkstr  no_drive,   "Drive not found."

            .section    dp
eol         .byte       ?
drives      .byte       ?
tmp         .word       ?
            .send            

            .section    data
prompt_len  .byte       ?
prompt_str  .fill       8
            .send

            .section    code

words       .namespace
            .align  256
base        .null   ""      ; So offset zero is invalid
help        .null   "help"
about       .null   "about"
ls          .null   "ls"
dir         .null   "dir"
read        .null   "read"
write       .null   "write"  
dump        .null   "dump" 
basic       .null   "basic"  
rename      .null   "rename"   
rm          .null   "rm"     
del         .null   "del"     
delete      .null   "delete"     
mkfs        .null   "mkfs"
keys        .null   "keys"
exec        .null   "exec"
mkdir       .null   "mkdir"     
rmdir       .null   "rmdir"     
wifi        .null   "wifi"
            .endn

commands
            .word   words.help,     help
            .word   words.about,    about
            .word   words.ls,       dir.cmd
            .word   words.dir,      dir.cmd
            .word   words.read,     read.cmd
            .word   words.write,    write.cmd
            .word   words.dump,     dump.cmd
            .word   words.basic,    dos.basic
            .word   words.rename,   rename.cmd
            .word   words.rm,       delete.cmd
            .word   words.del,      delete.cmd
            .word   words.delete,   delete.cmd
            .word   words.mkfs,     mkfs.cmd
            .word   words.keys,     keys.cmd
            .word   words.exec,     exec.cmd
            .word   words.mkdir,    mkdir.cmd
            .word   words.rmdir,    rmdir.cmd
            .word   words.wifi,     wifi.cmd
            .word   0

about
            jsr     hardware
            jsr     ukernel
            jsr     fat32
            rts        
hardware    
            phx

            lda     #>_msg
            ldx     #<_msg
            jsr     strings.puts_zero

            plx
            rts        
_msg
            .text   $0a
            .text   "Foenix F256 by Stefany Allaire", $0a
            .text   "https://c256foenix.com/f256-jr",$0a
            .text   $0a, $00

ukernel            
            phx

            lda     #>_msg
            ldx     #<_msg
            jsr     strings.puts_zero

            lda     #$E0
            ldx     #$08
            jsr     strings.puts_zero

            jsr     put_cr
            jsr     put_cr

            plx
            rts        
_msg
            .text   "TinyCore MicroKernel", $0a
            .text   "Copyright 2022 Jessie Oberreuter", $0a
            .text   "Gadget@HackwrenchLabs.com",$0a
            .text   "Built/revision: ",0

fat32
            phx

            ldx     #<_msg
            lda     #>_msg
            jsr     strings.puts_zero

            plx
            rts        

_msg
            .text   "Fat32 from https://github.com/commanderx16/x16-rom", $0a
            .text   "Copyright 2020 Frank van den Hoef and Michael Steil", $0a
            .text   $0a
            .text   "Simple DOS Shell, built ", DATE_STR, $0a
            .byte   $0
            

help
            lda     #<_msg
            sta     tmp+0
            lda     #>_msg
            sta     tmp+1
            phy
            ldy     #0
_loop       lda     (tmp),y
            beq     _done
            jsr     putc
            iny
            bne     _loop
            inc     tmp+1
            bra     _loop
_done
            ply
            rts        
_msg
            .byte   $0a
            .text   "<digit>:            Change drive.", $0a
            .text   "ls                  Shows the directory.",$0a
            .text   "dir                 Shows the directory.",$0a
            .text   "read   <fname>      Prints the contents of <fname>.", $0a
            .text   "write  <fname>      Writes user input to <fname>.", $0a
            .text   "dump   <fname>      Hex-dumps <fname>.", $0a
            .text   "rm     <fname>      Delete <fname>.", $0a
            .text   "del    <fname>      Delete <fname>.", $0a
            .text   "rename <old> <new>  Rename <old> to <new>.", $0a
            .text   "delete <fname>      Delete <fname>.", $0a
            .text   "mkfs   <label>      Creates a new filesystem on the device.", $0a
            .text   "basic               Starts SuperBASIC.", $0a
            .text   "keys                Demonstrates key status tracking.", $0a
            .text   "exec   <$hex>       JSR to a program in memory (try $a015).", $0a
            .text   "help                Prints this text.", $0a
            .text   "about               Information about the software and hardware.", $0a
            .text   "wifi <ssid> <pass>  Configures the wifi access point.", $0a
            .byte   $0

start
          ; Tell the event call where to dump events.
            lda     #<event
            sta     kernel.args.events+0
            lda     #>event
            sta     kernel.args.events+1

          ; Get the list of drives
            jsr     kernel.FileSystem.List
            sta     drives

          ; Print the list of drives
            jsr     print_drives

          ; Print the help text.
            lda     #help_str
            jsr     puts_cr

          ; Select the initial drive
            stz     drive

          ; Jump to the command loop
            jmp     run
            
print_drives
            lda     drives
            bne     _list
        
            lda     #nolist_str
            jmp     puts_cr

_list
            lda     #devlist_str
            jsr     puts
        
            lda     drives
            ldx     #'0'-1
_loop        
            lsr     a
            inx
            bcc     _next
            pha
            txa
            jsr     putc
            pla
_next
            bne     _loop
            jmp     put_cr
                
               
run
            jsr     put_cr
            jsr     prompt
            jsr     readline.read
            lda     readline.length
            cmp     #2
            bne     _cmd
            lda     readline.buf+1
            cmp     #':'
            bne     _cmd
            jmp     set_drive
_cmd
            jsr     readline.tokenize
            lda     readline.token_count
            beq     run
        
            jsr     dispatch
            bcc     _next
            
            jsr     put_cr
            lda     #failed_str
            jsr     puts_cr
_next
            bra     run


set_drive
            lda     readline.buf

            cmp     #'0' 
            bcc     _nope   

            cmp     #'7'+1 
            bcs     _nope   

            and     #7
            tay
            lda     _bits,y
            bit     drives
            beq     _unknown

            sty     drive
            bra     _done
_unknown
            lda     #no_drive_str
            jsr     strings.puts             
            jmp     _done
_bits       .byte   1,2,4,8,16,32,64,128            

_nope
            lda     #bad_drive_str
            jsr     strings.puts
_done
            jmp     run            

prompt
            jsr     set_prompt
            
            ldy     #0
_loop
            lda     prompt_str,y
            beq     _done
            jsr     display.putchar
            iny
            bra     _loop
_done
            sty     prompt_len
            sty     eol
            rts
             
set_prompt
            lda     drive
            clc
            adc     #'0'
            sta     prompt_str+0
            lda     #':'
            sta     prompt_str+1
            stz     prompt_str+2
            rts

dispatch
            ldx     #0
_cmd
            lda     commands,x
            beq     _fail
            inx
            inx        

            ldy     readline.tokens+0   ; offset of token zero.
            jsr     _cmp
            bcs     _next
            jmp     (commands,x)

_next        
            inx
            inx
            bra     _cmd
_fail
          ; Set up argument array for user programs
            jsr     readline.populate_arguments
.if true
          ; See if it's the name of a binary
            stz     kernel.args.buf+0
            lda     #>readline.buf
            sta     kernel.args.buf+1
            lda     #0
            jsr     readline.token_length
            tay
            lda     #0
            sta     (kernel.args.buf),y
            jsr     kernel.RunNamed
.endif
.if true
          ; Try to load an external user program on disk, kernel.args.buf is already initialized
            jsr     external.cmd
            bcs     _unknown_cmd
            rts
_unknown_cmd
.endif
          ; If the chain failed, unknown command.
            lda     #unknown_str
            jsr     strings.puts
            jmp     put_cr
        
_cmp
    ; a->offset in words
    ; y->token start

            phx
            tax

_loop
            lda     words.base,x
            cmp     readline.buf,y
            bne     _nope
            ora     readline.buf,y
            clc
            beq     _out
            inx
            iny
            bra     _loop
_nope
            sec
_out
            plx
            rts

            .send
            .endn
