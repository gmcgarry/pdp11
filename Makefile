.SUFFIXES: .asm .bin .lda .oct

all:    $(BINS)

clean:
	$(RM) *.lst *.bin *.lda *.oct

.SUFFIXES: .asm .bin .lda .s19

minibug.lda:	minibug.bin
	bin2load -i $< -o $@ -a 0140000

bootmon.lda:	bootmon.bin
	bin2load -i $< -o $@ -a 0140000

boot.lda:	boot.bin
	bin2load -i $< -o $@ -a 0140000

odt.lda:	odt.bin
	bin2load -i $< -o $@ -a 050000

odt2.lda:	odt2.bin
#	bin2load -i $< -o $@ -a 0170000
	bin2load -i $< -o $@ -a 050000

.bin.lda:
	bin2load -i $< -o $@ -a 02000

.asm.bin:
	pasm-pdp11 -d1000 -F bin -o $@ $< > $@.lst

.asm.oct:
	pasm-pdp11 -d1000 -F oct -o $@ $< > $@.lst

.asm.s19:
	pasm-pdp11 -d1000 -F srec2 -o $@ $< > $@.lst
