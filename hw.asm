        ; This program prints "Hello, world"
        ; (or any other string) on the serial console at 177650.
        ; Then it HALTs.
        ; On CONT, it repeats.

        serial = 177560         ; base addr of DL11

        .org 02000
start:
        mov     $serial+4,r2    ; r2 points to DL11 transmitter section
        mov     $string,r1      ; r1 points to the current character
nxtchr:
        movb    (r1)+,r0        ; load xmt char
        beq     done            ; string is terminated with 0
        movb    r0,2(r2)        ; write char to transmit buffer
loop:
	tstb    (r2)            ; character transmitted?
        bpl     loop            ; no, loop
        br      nxtchr          ; transmit nxt char of string
done:
	halt
        br      start
string:
        .ascii  "Hello, world"  ; arbitrary text
        .byte   12,0            ; LF char, end marker
        .end
