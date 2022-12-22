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
	dos/strings.asm \
	dos/display.asm \
	dos/readline.asm \
	dos/reader.asm \

COPT = -C -Wall -Werror -Wno-shadow -x --verbose-list

dos_jr.bin: $(DOS) kernel/api.asm
	64tass $(COPT) $^ -b -L $(basename $@).lst -o $@ -D DATE_STR=\"$(shell date +\"%d-%b-%y\")\"
	dd if=$@ of=kernel/01.bin ibs=8192 obs=8192 skip=0 count=1

bundle: refresh dos_jr.bin

# This is target isn't expected to work on your machine.
refresh:
	cp $(KERNEL)/kernel/api.asm kernel/api.asm
	cp $(KERNEL)/3e.bin kernel
	cp $(KERNEL)/3f.bin kernel
	cp $(KERNEL)/kernel.ram kernel
	

