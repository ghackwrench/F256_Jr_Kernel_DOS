always: hello.bin

.SUFFIXES:

CONFIGS	= f256jr.cfg
LIBS	= f256jr.lib 

OBJS = \
	name.o \
	hello.o \
	kernel.o \
	
f256jr.lib: ../lib/f256.lib
	cp $^ $@

kernel.o: kernel.c kernel.h $(CONFIGS) api.h
hello.o: hello.c kernel.h

hello.bin: $(OBJS) $(CONFIGS) $(LIBS)

%.o %.lst: %.s
	ca65 -t none --cpu 65C02 $< -l $(basename $@).lst

%.s: %.c
	cc65 -g --cpu 65C02 -t none -Os -I ../include -D_F256JR_ -T $< -o $@

%.bin:
	ld65 -C $(CONFIGS) -o $@ $(filter %.o, $^) $(LIBS) -m $(basename $@).map -Ln $(basename $@).lbl

