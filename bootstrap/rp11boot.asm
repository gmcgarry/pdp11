RPCSR = 0176700

	.ORG	140000

START:	RESET
        MOV     $RPCSR, R1
        MOV     $0000040, 10(R1)        ; RESET
        MOV     R3, 10(R1)              ; SET UNIT
        MOV     $0000021, (R1)          ; PACK ACK
        MOV     $0010000, 32(R1)        ; 16B MODE
        MOV     $-400, 2(R1)            ; SET WC
        CLR     4(R1)                   ; CLR BA
        CLR     6(R1)                   ; CLR DA
        CLR     34(R1)                  ; CLR CYL
        MOV     $0000071, (R1)          ; READ
1:	TSTB    (R1)                    ; WAIT
        BPL     1b
        CLRB    (R1)
        MOV     R3,R0
        CLR     PC

	.END
