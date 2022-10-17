RLCS = 174400

	.ORG	140000

START:	RESET
        SWAB    R3                      ; UNIT NUMBER
        MOV     $RLCS,R1                ; CSR
        MOV     $13,4(R1)               ; CLR ERR
        BIS     $4,R3                   ; UNIT+GSTAT
        MOV     R3,(R1)                 ; ISSUE CMD
1:	TSTB    (R1)                    ; WAIT
        BPL     1b
        CLRB    R3
        BIS     $10,R3                  ; UNIT+RDHDR
        MOV     R3,(R1)                 ; ISSUE CMD
1:	TSTB    (R1)                    ; WAIT
        BPL     1b
        MOV     6(R1),R2                ; GET HDR
        BIC     $77,R2                  ; CLR SECTOR
        INC     R2                      ; MAGIC BIT
        MOV     R2,4(R1)                ; SEEK TO 0
        CLRB    R3
        BIS     $6,R3                   ; UNIT+SEEK
        MOV     R3,(R1)                 ; ISSUE CMD
1:	TSTB    (R1)                    ; WAIT
        BPL     1b
        CLR     2(R1)                   ; CLR BA
        CLR     4(R1)                   ; CLR DA
        MOV     $-400,6(R1)             ; SET WC
        CLRB    R3
        BIS     $14,R3                  ; UNIT+READ
        MOV     R3,(R1)                 ; ISSUE CMD
1:	TSTB    (R1)                    ; WAIT
        BPL     1b
        BIC     $377,(R1)
        CLR     R2
        CLR     R3
        CLR     R4
        CLR     R5
        CLR     PC

	.END
