ORG 0X0
USE32
PROGRAM:
	.MAGIC        dd 0xAABBCCDD
	.Entry        dd main
	.Constants    dd Constants
	.GlobalCount  dd 

MAIN:
PushNull 13
LoadI R11,K0
PUSH R11
LoadI R11,K0
PUSH R11
LoadI R11,K1
PUSH R11
LoadI R11,K2
PUSH R11
LoadS R11,K3
PUSH R11
LoadS R11,K4
DoInvoke 5,1,R11
PUSH R1
LoadI R11,K0
PUSH R11
LoadI R11,K0
PUSH R11
LoadI R11,K5
PUSH R11
LoadI R11,K6
PUSH R11
LoadS R11,K7
DoInvoke 5,2,R11
LoadI R3,K8
LoadI R4,K8
LoadI R5,K9
LoadI R6,K10
LoadI R7,K8
LoadI R8,K8
LoadI R9,K8

;while
;begin while
LoadB R10,1
bTrue 1,R10,0
Jmp 0x000164
LoadI R12,K10
DoAdd R8,R8,R12
LoadI R12,K10
DoAdd R7,R7,R12
.FOR_INIT:
LoadI R9,K8
.FOR_COMPARE:
LoadI R11,K11
bA 0,R9,R11
Jmp 0x.FOR_END
LoadI R12,K10
DoAdd R9,R9,R12
Jmp 0x.FOR_COMPARE
.FOR_END:
PUSH R2
PUSH R3
PUSH R4
LoadI R12,K0
PUSH R12
LoadI R12,K0
PUSH R12
PUSH R8
LoadS R12,K12
DoInvoke 6,11,R12
PUSH R2
LoadS R12,K13
DoInvoke 1,11,R12
DoAdd R4,R4,R6
DoAdd R3,R3,R5

;if
LoadI R11,K5
bLT 0,R3,R11
Jmp 0x000118
DoSub R3,R3,R5
LoadI R13,K8
DoSub R5,R13,R5
;END IF

;if
LoadI R11,K8
bLT 1,R3,R11
Jmp 0x000130
DoSub R3,R3,R5
LoadI R13,K8
DoSub R5,R13,R5
;END IF

;if
LoadI R11,K6
bLT 0,R4,R11
Jmp 0x000148
DoSub R4,R4,R6
LoadI R13,K8
DoSub R6,R13,R6
;END IF

;if
LoadI R11,K8
bLT 1,R4,R11
Jmp 0x000160
DoSub R4,R4,R6
LoadI R13,K8
DoSub R6,R13,R6
;END IF
;END WHILE
;end of if block
Jmp 0x00008C
DoRet
Constants:
	.K0 dd 10
	.K1 dd 350
	.K2 dd 235
	.K3 dd Strings.S0
	.K4 dd Strings.S1
	.K5 dd 330
	.K6 dd 215
	.K7 dd Strings.S2
	.K8 dd 0
	.K9 dd 2
	.K10 dd 1
	.K11 dd 100
	.K12 dd Strings.S3
	.K13 dd Strings.S4
Strings:
	.S db "Demo APP",0
	.S db "WINDOW.CREATE",0
	.S db "IMAGE.CREATE",0
	.S db "IMAGE.FILLRECTANGLE",0
	.S db "IMAGE.FLUSH",0
