always: hello.bin
clean:
	rm *.o

.SUFFIXES:

CONFIGS	= f256jr.cfg
LIBS	= f256jr.lib 

OBJS = \
	name.o \
	hello.o \
	kernel.o \
	
f256jr.lib: ../lib/f256.lib
	cp $^ $@

kernel.o: kernel.c $(CONFIGS) api.h
hello.o: hello.c

hello.bin: $(OBJS) $(CONFIGS) $(LIBS)

%.o %.lst: %.s
	ca65 -t none --cpu 65C02 $< -l $(basename $@).lst

%.s: %.c
	cc65 -g --cpu 65C02 -t none -Os -I . -D_F256JR_ -T $< -o $@

%.bin:
	ld65 -C $(CONFIGS) -o $@ $(filter %.o, $^) $(LIBS) -m $(basename $@).map -Ln $(basename $@).lbl

