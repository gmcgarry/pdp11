SRCS = rf11boot.asm tc11boot.asm tmboot.asm rp11boot.asm rk11boot.asm rl11boot.asm
BINS = $(SRCS:.asm=.pdp11)

all:	$(BINS)

clean:
	$(RM) *.lst *.bin *.pdp11

.SUFFIXES: .asm .bin .pdp11

.bin.pdp11:
	bin2load -i $< -o $@ -a 02000

.asm.bin:
	pasm-pdp11 -d1000 -F bin -o $@ $< > $@.lst

tmboot.pdp11:	tmboot.bin
	bin2load -i $< -o $@ -a 0100000

#bootmon.pdp11:	bootmon.bin
#	bin2load -i $< -o $@ -a 0140000

# load at $C000
minibug.pdp11:	minibug.bin
	bin2load -i $< -o $@ -a 0140000
