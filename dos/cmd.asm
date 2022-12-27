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
        
            .mkstr  devlist,    "Drives found: "
            .mkstr  nolist,     "No drives found."
            .mkstr  unknown,    "Unknown command."
            .mkstr  failed,     "Command failed."
            .mkstr  help,       "Enter 'help' for help."

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
            .endn

commands
            .word   words.help,     help
            .word   words.ls,       dir.cmd
            .word   words.dir,      dir.cmd
            .word   words.read,     read.cmd
            .word   words.write,    write.cmd
            .word   words.dump,     dump.cmd
            .word   words.basic,    basic
            .word   words.rename,   rename.cmd
            .word   words.rm,       delete.cmd
            .word   words.del,      delete.cmd
            .word   words.delete,   delete.cmd
            .word   words.mkfs,     mkfs.cmd
            .word   words.keys,     keys.cmd
            .word   words.exec,     exec.cmd
            .word   0

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

          ; Y = initial drive #
            lda     drives
            and     #3  ; Just select the floppies for now.
            tay
            
          ; Select the initial drive
            lda     _drive,y
            sta     drive

          ; Jump to the command loop
            jmp     run

_drive      .byte   0,0,1,0

set_prompt
            ldy     drive
            lda     _letter,y
            sta     prompt_str+0
            lda     #':'
            sta     prompt_str+1
            stz     prompt_str+2
            rts
_letter     .text   "$ABA"
            
print_drives
            lda     drives
            bne     _list
        
            lda     #nolist_str
            jmp     puts_cr

_list
            lda     #devlist_str
            jsr     puts
        
            lda     drives
            ldx     #'@'
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
