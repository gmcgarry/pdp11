.SUFFIXES: .asm .bin .pdp11

all:    $(BINS)

clean:
	$(RM) *.lst *.bin *.pdp11

.SUFFIXES: .asm .bin .pdp11

minibug.pdp11:	minibug.bin
	bin2load -i $< -o $@ -a 0140000


.bin.pdp11:
	bin2load -i $< -o $@ -a 02000

.asm.bin:
	pasm-pdp11 -d1000 -F bin -o $@ $< > $@.lst
