BINS = odt.lda minibug.lda

.SUFFIXES: .asm .bin .lda

all:    $(BINS)

clean:
	$(RM) *.lst *.bin *.lda *.oct

minibug.lda:	minibug.bin
	bin2load -i $< -o $@ -a 0140000

odt.lda:	odt.bin
	bin2load -i $< -o $@ -a 0140000

.SUFFIXES: .asm .bin .lda .s19

.bin.lda:
	bin2load -i $< -o $@ -a 02000

.asm.bin:
	pasm-pdp11 -d1000 -F bin -o $@ $< > $@.lst

.asm.oct:
	pasm-pdp11 -d1000 -F oct -o $@ $< > $@.lst

.asm.s19:
	pasm-pdp11 -d1000 -F srec2 -o $@ $< > $@.lst
