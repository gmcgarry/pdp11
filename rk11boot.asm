RKDA = 177412
READGO = 5

	.ORG 140000

START:  RESET
        SWAB    R3                      ; UNIT NUMBER
        ASL     R3
        ASL     R3
        ASL     R3
        ASL     R3
        ASL     R3
        MOV     $RKDA,R1                ; CSR
        MOV     R3,(R1)                 ; LOAD DA
        CLR     -(R1)                   ; CLEAR BA
        MOV     $-400,-(R1)             ; LOAD WC
        MOV     $READGO,-(R1)           ; READ & GO
        CLR     R2
        CLR     R3
        CLR     R4
        CLR     R5
1:	TSTB    (R1)
        BPL     1b
        CLRB    (R1)
        CLR     PC

	.END
