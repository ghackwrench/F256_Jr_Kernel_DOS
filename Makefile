KERNEL  = ../TinyCore/kernels/jr

DOS	= \
	dos/dos.asm \
	dos/cmd.asm \
	dos/cmd_dir.asm \
	dos/cmd_read.asm \
	dos/cmd_write.asm \
	dos/cmd_dump.asm \
	dos/cmd_rename.asm \
	dos/cmd_delete.asm \
	dos/cmd_mkfs.asm \
	dos/cmd_mkdir.asm \
	dos/cmd_rmdir.asm \
	dos/cmd_keys.asm \
	dos/cmd_exec.asm \
	dos/cmd_wifi.asm \
	dos/cmd_external.asm \
	dos/strings.asm \
	dos/display.asm \
	dos/readline.asm \
	dos/reader.asm \
	kernel/api.asm \
	kernel/keys.asm

COPT = -C -Wall -Werror -Wno-shadow -x --verbose-list -I .

dos_jr.bin: $(DOS) kernel/keys.asm
	64tass $(COPT) $(DOS) -b -L $(basename $@).lst -o $@ -D DATE_STR=\"$(shell date +\"%d-%b-%y\")\"
	dd if=$@ of=kernel/dos.bin ibs=8192 obs=8192 skip=0 count=1

bundle: refresh dos_jr.bin

# This is target isn't expected to work on your machine.
refresh:
	cp $(KERNEL)/kernel/api.asm kernel/api.asm
	cp $(KERNEL)/3b.bin kernel
	cp $(KERNEL)/3c.bin kernel
	cp $(KERNEL)/3d.bin kernel
	cp $(KERNEL)/3e.bin kernel
	cp $(KERNEL)/3f.bin kernel
	cp $(KERNEL)/kernel.ram kernel
	cp $(KERNEL)/hardware/keys.asm kernel
	cp $(KERNEL)/docs/README.md kernel
	

