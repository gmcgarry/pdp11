SRCS = bm792.asm mb9312.asm rf11load.asm tc11load.asm tm11load.asm rp11load.asm rk11load.asm rl11load.asm pc11load.asm absload.asm multiload.asm tu58load.asm rx11load.asm
BINS = $(SRCS:.asm=.lda)

all:	$(BINS)

tm11load.lda:	tm11load.bin
	bin2load -i $< -o $@ -a 017764

clean:
	$(RM) *.lst *.bin *.lda

.SUFFIXES: .asm .bin .lda

.bin.lda:
	bin2load -i $< -o $@ -a 02000

.asm.bin:
	pasm-pdp11 -d1000 -F bin -o $@ $< > $@.lst
