SRCS = bm792.asm mb9312.asm rf11boot.asm tc11boot.asm tmboot.asm rp11boot.asm rk11boot.asm rl11boot.asm pc11boot.asm absload.asm
BINS = $(SRCS:.asm=.lda)

all:	$(BINS)

clean:
	$(RM) *.lst *.bin *.lda

.SUFFIXES: .asm .bin .lda

.bin.lda:
	bin2load -i $< -o $@ -a 02000

.asm.bin:
	pasm-pdp11 -d1000 -F bin -o $@ $< > $@.lst

tmboot.lda:	tmboot.bin
	bin2load -i $< -o $@ -a 0100000
