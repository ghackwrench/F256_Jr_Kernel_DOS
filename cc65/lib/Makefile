always: f256.lib

f256.lib: common.lib crt0.o mainargs.o

%.o %.lst:%.s
	ca65 -o $@ $^ -l $(basename $@).lst
	
%.lib:
	cp $(filter %.lib, $^) $@
	ar65 r $@ $(filter %.o, $^)
	
