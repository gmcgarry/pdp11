; INTERRUPT VECTORS
DL11VEC         =       64	; 0x34
KW11VEC         =       100	; 0x40
PIRVEC		=	240	; 0x58
PIRPSW		=	242

; UNIBUS MAP REGISTERS
UNIBUS		=	0170200		; 11/44, 11/70

; KW11-L LINE-TIME CLOCK
CLKCSR		=	0170404
CLKBUF		=	0170406
CLKCTR		=	0170430

; RJS04/RWS04/RS04/RJS04/RWS04/RS03 DISK (0172040-0172072)
SIPDR		=	0172200		; supervisor instruction PDR, reg 0-7
SDPDR		=	0172220		; supervisor data PDR, reg 0-7
SIPAR		=	0172240		; supervisor instruction PAR, reg 0-7
SDPAR		=	0172260		; supervisor data PAR, reg 0-7
KIPDR		=	0172300		; kernel instruction PDR, reg 0-7
KDPDR		=	0172320		; kernel data PDR, reg 0-7
KIPAR		=	0172340		; kernel instruction PAR, reg 0-7
KDPAR		=	0172360		; kernel data PAR, reg 0-7

; KW11-W WATCHDOG TIMER
WDCSR		=	0172400
WDCFR		=	0172402
WDECSR		=	0172404
WDSSR		=	0172406

; TU16/TWU16/TJU16 TAPE (0172440-0172476)

; TM11 MAGNETIC TAPE (800DPI 9TRACK)
MTS		=	0172520		; status
MTC		=	0172522		; command
MTBRC		=	0172524		; byte record counter
MTCMA		=	0172526		; current memory address
MTD		=	0172530		; data buffer
MTRD		=	0172532		; read lines

; RL11 CARTRIDGE DISK (5-10MB)
RLCS		=	0174400

; TU58 DECTAPE
TUSLU		=	0176500

; RP11 MASSBUSS DISK (87MB-174MB,516MB)
RPCSR		=	0176700

; RJP04/RWP04/RP04 DISK (0176700-0176752)


; RP11-C/RP03/RPR11/RPR02
RPDS		=	0176710		; device status
RPER		=	0176712		; error
RPCS		=	0176714		; control status
RPWC		=	0176716		; word count
RPBA		=	0176720		; bus address
RPCA		=	0176722		; cylinder address
RPDA		=	0176724		; disk address
RPM1		=	0176726		; maintenance 1
RPM2		=	0176730		; maintenance 2
RPM3		=	0176732		; maintenance 3
SUCA		=	0176734		; selected unit cylinder address
SILO		=	0176736		; silo memory

; CD11 HIGH SPEED CARD READER
CDST		=	0177160		; status and control
CDCC		=	0177162		; column count
CDBA		=	0177164		; current address
CCDDB		=	0177166		; data

; CR11 CARD READER
CRS		=	01777160	; status
CRB1		=	01777162	; buffer, 12-bit char
CRB2		=	01777164	; buffer, 8-bit char

; RX11/RX01 FLOPPY DISK
RXCS		=	01777170	; command and status
RXDB		=	01777172	; data buffer

; TC11 DECtape (296KB)
TCST		=	0177340		; control and status
TCCM		=	0177342		; command
TCWC		=	0177344		; word cound
TCBA		=	0177346		; bus address
TCDT		=	0177350		; data

; RK11/05 CARTRIDGE DISK (13-26MB)
RKDS		=	0177400		; drive status
RKER		=	0177402		; error
RKCS		=	0177404		; control and status
RKWC		=	0177406		; word count
RKBA		=	0177410		; current base address
RKDA		=	0177412		; disk address
	READGO	=	5
RKDB		=	0177416		; data buffer

; RF11/RS11 FIXED-HEAD DISK (256-2048KW)
RFDCR		=	0177460		; disk control/status
RFWC		=	0177462		; word count
RFCMA		=	0177464		; current mem address
RFDAR		=	0177466		; disk address
RFDAE		=	0177470		; disk address ext and error
RFDBR		=	0177472		; disk data buffer
RFMA		=	0177474		; maintenance
RFADS		=	0177476		; address of disk segment

; TA11 CASSETTE
TACS		=	0177500		; command and status
TADB		=	0177502		; data buffer

; LP11 LINE PRINTER
LPST		=	0177514
LPDA		=	0177516

; KW11-L LINE CLOCK (50 or 60Hz)
KW11LKS		=       0177546
	INTE	=	100
	INTF	=	200

; KW11-P PROGRAMMABLE CLOCK

; PC11 PAPER-TAPE READER (177550-177557)
PRS		=	0177550		; reader status
PRB		=	0177552		; reader buffer
PPS		=	0177554		; punch status
PPB		=	0177556		; punch buffer

; KL11 TELETYPE CONSOLE TERMINAL (0177560 - 177566)
KL11RCSR	=	0177560
KL11RBUF	=	0177562
KL11XCSR	=	0177564
KL11XBUF	=	0177566

; DL11 FULL-DUPLEX ASYNCHRONOUS INTERFACE (TTY CONSOLE)
; MODEL 33 TELEPRINTER
DL11RCSR        =       0177560
DL11RBUF        =       0177562
DL11XCSR	=	0177564
	TXRDY	=	0200		; 0x0080
DL11XBUF	=	0177566

; SWITCH REGISTER OR CONFIGURATION REGISTER
SR		=	0177570
SDR		=	0177570		; switch and display register

; MMU
MMR0		=	0177572
MMR1		=	0177574
MMR2		=	0177576
MMR3		=	0172516		; ???? 

; KW11-P PROGRAMMABLE CLOCK
KW11PST		=	0177640		; control and status
KW11PCSB	=	0177642		; count set buffer
KW11PCNT	=	0177644		; counter

; SYSTEM REGISTERS
PDRI		=	0177600		; user instruction PDR, reg 0-7
PDRD		=	0177620		; user data PDR, reg 0-7
PARI		=	0177640		; user instruction PAR, reg 0-7
PARD		=	0177660		; user data PAR, reg 0-7

_R0		=	0177700		; CPU registers
_R1		=	0177701
_R2		=	0177702
_R3		=	0177703
_R4		=	0177704
_R5		=	0177705
_R6		=	0177706
_R7		=	0177707

EADDRL		=	0177740		; cache: low error address
EADDRH		=	0177742		; cache: low error address
MSYSERR		=	0177744		; cache: memory system error
MCTRL		=	0177746		; cache: memory control
MMNT		=	0177750		; cache: maintenance
HITMISS		=	0177752		; cache: hit/miss

MNT		=	0177750
MR		=	0177752
SIZEL		=	0177760		; lower size register
SIZEH		=	0177762		; upper size register
ID		=	0177764		; system id register
CER		=	0177766		; CPU error
MBR		=	0177770		; 11/45 and 11/70 microprogram break register
PIR		=	0177772		; programmed interrupt request - traps (11/44, 11/45, 11/70, J11)
SLR		=	0177774 	; stack limit register
PSW             =       0177776		; processor status word (KA11)
