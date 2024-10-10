ORG 0X0
USE32
PROGRAM:
	.MAGIC        dd 0xAABBCCDD
	.Entry        dd main
	.Constants    dd Constants
	.GlobalCount  dd 

MAIN:
PushNull 3
LoadI R2,K0
PUSH R2
LoadI R2,K0
PUSH R2
LoadI R2,K1
PUSH R2
LoadI R2,K2
PUSH R2
LoadS R2,K3
PUSH R2
LoadS R2,K4
DoInvoke 5,1,R2
setGlobal G0,R1
getGlobal R2,G0
PUSH R2
LoadI R2,K0
PUSH R2
LoadI R2,K0
PUSH R2
LoadI R2,K5
PUSH R2
LoadI R2,K6
PUSH R2
LoadS R2,K7
PUSH R2
LoadS R2,K8
DoInvoke 6,1,R2
getGlobal R2,G0
PUSH R2
LoadI R2,K0
PUSH R2
LoadI R2,K9
PUSH R2
LoadI R2,K10
PUSH R2
LoadI R2,K11
PUSH R2
LoadS R2,K12
DoInvoke 5,1,R2
setGlobal G1,R1
getGlobal R2,G0
PUSH R2
LoadI R2,K0
PUSH R2
LoadI R2,K13
PUSH R2
LoadI R2,K5
PUSH R2
LoadI R2,K6
PUSH R2
LoadS R2,K14
PUSH R2
LoadS R2,K8
DoInvoke 6,1,R2
getGlobal R2,G0
PUSH R2
LoadI R2,K0
PUSH R2
LoadI R2,K15
PUSH R2
LoadI R2,K10
PUSH R2
LoadI R2,K11
PUSH R2
LoadS R2,K12
DoInvoke 5,1,R2
setGlobal G2,R1
getGlobal R2,G0
PUSH R2
LoadI R2,K0
PUSH R2
LoadI R2,K16
PUSH R2
LoadI R2,K17
PUSH R2
LoadI R2,K6
PUSH R2
LoadS R2,K18
PUSH R2
LoadS R2,K8
DoInvoke 6,1,R2
getGlobal R2,G0
PUSH R2
LoadI R2,K0
PUSH R2
LoadI R2,K19
PUSH R2
LoadI R2,K17
PUSH R2
LoadI R2,K11
PUSH R2
LoadS R2,K12
DoInvoke 5,1,R2
setGlobal G3,R1
getGlobal R2,G0
PUSH R2
LoadI R2,K20
PUSH R2
LoadI R2,K16
PUSH R2
LoadI R2,K21
PUSH R2
LoadI R2,K6
PUSH R2
LoadS R2,K22
PUSH R2
LoadS R2,K8
DoInvoke 6,1,R2
getGlobal R2,G0
PUSH R2
LoadI R2,K20
PUSH R2
LoadI R2,K19
PUSH R2
LoadI R2,K21
PUSH R2
LoadI R2,K11
PUSH R2
LoadS R2,K12
DoInvoke 5,1,R2
setGlobal G4,R1
getGlobal R2,G0
PUSH R2
LoadI R2,K0
PUSH R2
LoadI R2,K23
PUSH R2
LoadI R2,K21
PUSH R2
LoadI R2,K6
PUSH R2
LoadS R2,K24
PUSH R2
LoadS R2,K8
DoInvoke 6,1,R2
getGlobal R2,G0
PUSH R2
LoadI R2,K0
PUSH R2
LoadI R2,K25
PUSH R2
LoadI R2,K21
PUSH R2
LoadI R2,K11
PUSH R2
LoadS R2,K12
DoInvoke 5,1,R2
setGlobal G5,R1
getGlobal R2,G0
PUSH R2
LoadI R2,K26
PUSH R2
LoadI R2,K23
PUSH R2
LoadI R2,K17
PUSH R2
LoadI R2,K6
PUSH R2
LoadS R2,K27
PUSH R2
LoadS R2,K8
DoInvoke 6,1,R2
getGlobal R2,G0
PUSH R2
LoadI R2,K26
PUSH R2
LoadI R2,K25
PUSH R2
LoadI R2,K17
PUSH R2
LoadI R2,K11
PUSH R2
LoadS R2,K12
DoInvoke 5,1,R2
setGlobal G6,R1
getGlobal R2,G0
PUSH R2
LoadI R2,K0
PUSH R2
LoadI R2,K28
PUSH R2
LoadI R2,K17
PUSH R2
LoadI R2,K6
PUSH R2
LoadS R2,K29
PUSH R2
LoadS R2,K8
DoInvoke 6,1,R2
getGlobal R2,G0
PUSH R2
LoadI R2,K0
PUSH R2
LoadI R2,K17
PUSH R2
LoadI R2,K10
PUSH R2
LoadI R2,K11
PUSH R2
LoadS R2,K12
DoInvoke 5,1,R2
setGlobal G7,R1
getGlobal R2,G0
PUSH R2
LoadI R2,K0
PUSH R2
LoadI R2,K30
PUSH R2
LoadI R2,K17
PUSH R2
LoadI R2,K6
PUSH R2
LoadS R2,K31
PUSH R2
LoadS R2,K8
DoInvoke 6,1,R2
getGlobal R2,G0
PUSH R2
LoadI R2,K0
PUSH R2
LoadI R2,K32
PUSH R2
LoadI R2,K10
PUSH R2
LoadI R2,K11
PUSH R2
LoadS R2,K12
DoInvoke 5,1,R2
setGlobal G8,R1
getGlobal R2,G0
PUSH R2
LoadI R2,K0
PUSH R2
LoadI R2,K33
PUSH R2
LoadI R2,K17
PUSH R2
LoadI R2,K6
PUSH R2
LoadS R2,K34
PUSH R2
LoadS R2,K8
DoInvoke 6,1,R2
getGlobal R2,G0
PUSH R2
LoadI R2,K0
PUSH R2
LoadI R2,K35
PUSH R2
LoadI R2,K10
PUSH R2
LoadI R2,K11
PUSH R2
LoadS R2,K12
DoInvoke 5,1,R2
setGlobal G9,R1
getGlobal R2,G0
PUSH R2
LoadI R2,K0
PUSH R2
LoadI R2,K36
PUSH R2
LoadI R2,K9
PUSH R2
LoadI R2,K9
PUSH R2
LoadS R2,K37
PUSH R2
LoadI R2,K38
PUSH R2
LoadI R2,K39
PUSH R2
LoadS R2,K40
DoInvoke 8,1,R2
setGlobal G10,R1
getGlobal R2,G0
PUSH R2
LoadI R2,K41
PUSH R2
LoadI R2,K36
PUSH R2
LoadI R2,K9
PUSH R2
LoadI R2,K9
PUSH R2
LoadS R2,K42
PUSH R2
LoadI R2,K38
PUSH R2
LoadI R2,K43
PUSH R2
LoadS R2,K40
DoInvoke 8,1,R2
setGlobal G11,R1
getGlobal R2,G0
PUSH R2
LoadI R2,K20
PUSH R2
LoadI R2,K36
PUSH R2
LoadI R2,K9
PUSH R2
LoadI R2,K9
PUSH R2
LoadS R2,K44
PUSH R2
LoadI R2,K38
PUSH R2
LoadI R2,K45
PUSH R2
LoadS R2,K40
DoInvoke 8,1,R2
setGlobal G12,R1
getGlobal R2,G0
PUSH R2
LoadI R2,K5
PUSH R2
LoadI R2,K36
PUSH R2
LoadI R2,K9
PUSH R2
LoadI R2,K9
PUSH R2
LoadS R2,K46
PUSH R2
LoadI R2,K38
PUSH R2
LoadI R2,K47
PUSH R2
LoadS R2,K40
DoInvoke 8,1,R2
setGlobal G13,R1
DoCall 0,1,0,newitem
DoCall 0,1,0,loadfile
DoRet

LOADFILE:
PushNull 9
newArray R1
setGlobal G15,R1
LoadI R1,K38
setGlobal G17,R1
LoadS R2,K48
PUSH R2
LoadS R2,K49
DoInvoke 1,0,R2
LoadS R2,K50
PUSH R2
LoadS R2,K51
DoInvoke 1,1,R2

;while
;begin while
PUSH R0
LoadS R2,K52
DoInvoke 1,1,R2
LoadI R2,K38
bEQ 1,R1,R2
Jmp 0x0006E8
getGlobal R4,G17
LoadI R5,K53
DoAdd R3,R4,R5
setGlobal G17,R3
newArray R3
getGlobal R5,G15
getGlobal R6,G17
setArray R5 , R6 , R3
PUSH R0
LoadS R4,K55
DoInvoke 1,3,R4
getGlobal R6,G15
getGlobal R7,G17
getArray R5 , R6 , R7
LoadS R6,K54
setArray R5 , R6 , R3
PUSH R0
LoadS R4,K55
DoInvoke 1,3,R4
getGlobal R6,G15
getGlobal R7,G17
getArray R5 , R6 , R7
LoadS R6,K56
setArray R5 , R6 , R3
PUSH R0
LoadS R4,K55
DoInvoke 1,3,R4
getGlobal R6,G15
getGlobal R7,G17
getArray R5 , R6 , R7
LoadS R6,K57
setArray R5 , R6 , R3
PUSH R0
LoadS R4,K55
DoInvoke 1,3,R4
getGlobal R6,G15
getGlobal R7,G17
getArray R5 , R6 , R7
LoadS R6,K58
setArray R5 , R6 , R3
PUSH R0
LoadS R4,K55
DoInvoke 1,3,R4
getGlobal R6,G15
getGlobal R7,G17
getArray R5 , R6 , R7
LoadS R6,K59
setArray R5 , R6 , R3
PUSH R0
LoadS R4,K55
DoInvoke 1,3,R4
getGlobal R6,G15
getGlobal R7,G17
getArray R5 , R6 , R7
LoadS R6,K60
setArray R5 , R6 , R3
PUSH R0
LoadS R4,K55
DoInvoke 1,3,R4
getGlobal R6,G15
getGlobal R7,G17
getArray R5 , R6 , R7
LoadS R6,K61
setArray R5 , R6 , R3
PUSH R0
LoadS R4,K55
DoInvoke 1,3,R4
getGlobal R6,G15
getGlobal R7,G17
getArray R5 , R6 , R7
LoadS R6,K62
setArray R5 , R6 , R3
PUSH R0
LoadS R4,K55
DoInvoke 1,3,R4
getGlobal R6,G15
getGlobal R7,G17
getArray R5 , R6 , R7
LoadS R6,K63
setArray R5 , R6 , R3
;END WHILE
;end of if block
Jmp 0x00058C
LoadS R2,K64
PUSH R2
LoadS R2,K51
DoInvoke 1,1,R2
getGlobal R1,G17
getGlobal R3,G15
LoadS R4,K65
setArray R3 , R4 , R1
getGlobal R1,G17
setGlobal G16,R1
PUSH R0
LoadS R2,K66
DoInvoke 1,1,R2
DoCall 0,1,0,loadcurrent
DoRet

SAVEFILE:
PushNull 7
LoadS R3,K48
PUSH R3
LoadS R3,K49
DoInvoke 1,0,R3
PUSH R0
LoadS R3,K67
DoInvoke 1,2,R3
.FOR_INIT:
LoadI R1,K53
.FOR_COMPARE:
getGlobal R2,G17
bA 0,R1,R2
Jmp 0x.FOR_END
PUSH R0
getGlobal R6,G15
getArray R5 , R6 , R1
LoadS R6,K54
getArray R4 , R5 , R6
PUSH R4
LoadS R4,K68
DoInvoke 2,3,R4
PUSH R0
getGlobal R6,G15
getArray R5 , R6 , R1
LoadS R6,K56
getArray R4 , R5 , R6
PUSH R4
LoadS R4,K68
DoInvoke 2,3,R4
PUSH R0
getGlobal R6,G15
getArray R5 , R6 , R1
LoadS R6,K57
getArray R4 , R5 , R6
PUSH R4
LoadS R4,K68
DoInvoke 2,3,R4
PUSH R0
getGlobal R6,G15
getArray R5 , R6 , R1
LoadS R6,K58
getArray R4 , R5 , R6
PUSH R4
LoadS R4,K68
DoInvoke 2,3,R4
PUSH R0
getGlobal R6,G15
getArray R5 , R6 , R1
LoadS R6,K59
getArray R4 , R5 , R6
PUSH R4
LoadS R4,K68
DoInvoke 2,3,R4
PUSH R0
getGlobal R6,G15
getArray R5 , R6 , R1
LoadS R6,K60
getArray R4 , R5 , R6
PUSH R4
LoadS R4,K68
DoInvoke 2,3,R4
PUSH R0
getGlobal R6,G15
getArray R5 , R6 , R1
LoadS R6,K61
getArray R4 , R5 , R6
PUSH R4
LoadS R4,K68
DoInvoke 2,3,R4
PUSH R0
getGlobal R6,G15
getArray R5 , R6 , R1
LoadS R6,K62
getArray R4 , R5 , R6
PUSH R4
LoadS R4,K68
DoInvoke 2,3,R4
PUSH R0
getGlobal R6,G15
getArray R5 , R6 , R1
LoadS R6,K63
getArray R4 , R5 , R6
PUSH R4
LoadS R4,K68
DoInvoke 2,3,R4
LoadI R3,K53
DoAdd R1,R1,R3
Jmp 0x.FOR_COMPARE
.FOR_END:
PUSH R0
LoadS R3,K66
DoInvoke 1,2,R3
DoRet

LOADEMPTY:
PushNull 4
getGlobal R1,G1
PUSH R1
LoadS R1,K69
PUSH R1
LoadS R1,K70
DoInvoke 2,0,R1
getGlobal R1,G2
PUSH R1
LoadS R1,K69
PUSH R1
LoadS R1,K70
DoInvoke 2,0,R1
getGlobal R1,G3
PUSH R1
LoadS R1,K69
PUSH R1
LoadS R1,K70
DoInvoke 2,0,R1
getGlobal R1,G4
PUSH R1
LoadS R1,K69
PUSH R1
LoadS R1,K70
DoInvoke 2,0,R1
getGlobal R1,G5
PUSH R1
LoadS R1,K69
PUSH R1
LoadS R1,K70
DoInvoke 2,0,R1
getGlobal R1,G6
PUSH R1
LoadS R1,K69
PUSH R1
LoadS R1,K70
DoInvoke 2,0,R1
getGlobal R1,G7
PUSH R1
LoadS R1,K69
PUSH R1
LoadS R1,K70
DoInvoke 2,0,R1
getGlobal R1,G8
PUSH R1
LoadS R1,K69
PUSH R1
LoadS R1,K70
DoInvoke 2,0,R1
getGlobal R1,G9
PUSH R1
LoadS R1,K69
PUSH R1
LoadS R1,K70
DoInvoke 2,0,R1
DoRet

SAVECURRENT:
PushNull 11

;if
getGlobal R0,G16
LoadI R1,K38
bA 1,R0,R1
Jmp 0x000ADC

;if
getGlobal R2,G16
getGlobal R3,G17
bA 0,R2,R3
Jmp 0x000ADC
getGlobal R5,G1
PUSH R5
LoadS R5,K71
DoInvoke 1,4,R5
getGlobal R7,G15
getGlobal R8,G16
getArray R6 , R7 , R8
LoadS R7,K54
setArray R6 , R7 , R4
getGlobal R5,G2
PUSH R5
LoadS R5,K71
DoInvoke 1,4,R5
getGlobal R7,G15
getGlobal R8,G16
getArray R6 , R7 , R8
LoadS R7,K56
setArray R6 , R7 , R4
getGlobal R5,G3
PUSH R5
LoadS R5,K71
DoInvoke 1,4,R5
getGlobal R7,G15
getGlobal R8,G16
getArray R6 , R7 , R8
LoadS R7,K57
setArray R6 , R7 , R4
getGlobal R5,G4
PUSH R5
LoadS R5,K71
DoInvoke 1,4,R5
getGlobal R7,G15
getGlobal R8,G16
getArray R6 , R7 , R8
LoadS R7,K58
setArray R6 , R7 , R4
getGlobal R5,G5
PUSH R5
LoadS R5,K71
DoInvoke 1,4,R5
getGlobal R7,G15
getGlobal R8,G16
getArray R6 , R7 , R8
LoadS R7,K59
setArray R6 , R7 , R4
getGlobal R5,G6
PUSH R5
LoadS R5,K71
DoInvoke 1,4,R5
getGlobal R7,G15
getGlobal R8,G16
getArray R6 , R7 , R8
LoadS R7,K60
setArray R6 , R7 , R4
getGlobal R5,G7
PUSH R5
LoadS R5,K71
DoInvoke 1,4,R5
getGlobal R7,G15
getGlobal R8,G16
getArray R6 , R7 , R8
LoadS R7,K61
setArray R6 , R7 , R4
getGlobal R5,G8
PUSH R5
LoadS R5,K71
DoInvoke 1,4,R5
getGlobal R7,G15
getGlobal R8,G16
getArray R6 , R7 , R8
LoadS R7,K62
setArray R6 , R7 , R4
getGlobal R5,G9
PUSH R5
LoadS R5,K71
DoInvoke 1,4,R5
getGlobal R7,G15
getGlobal R8,G16
getArray R6 , R7 , R8
LoadS R7,K63
setArray R6 , R7 , R4
;END IF
;END IF
DoRet

LOADCURRENT:
PushNull 11

;if
getGlobal R0,G16
LoadI R1,K38
bA 1,R0,R1
Jmp 0x000C7C

;if
getGlobal R2,G16
getGlobal R3,G17
bA 0,R2,R3
Jmp 0x000C70
getGlobal R5,G1
PUSH R5
getGlobal R7,G15
getGlobal R8,G16
getArray R6 , R7 , R8
LoadS R7,K54
getArray R5 , R6 , R7
PUSH R5
LoadS R5,K70
DoInvoke 2,4,R5
getGlobal R5,G2
PUSH R5
getGlobal R7,G15
getGlobal R8,G16
getArray R6 , R7 , R8
LoadS R7,K56
getArray R5 , R6 , R7
PUSH R5
LoadS R5,K70
DoInvoke 2,4,R5
getGlobal R5,G3
PUSH R5
getGlobal R7,G15
getGlobal R8,G16
getArray R6 , R7 , R8
LoadS R7,K57
getArray R5 , R6 , R7
PUSH R5
LoadS R5,K70
DoInvoke 2,4,R5
getGlobal R5,G4
PUSH R5
getGlobal R7,G15
getGlobal R8,G16
getArray R6 , R7 , R8
LoadS R7,K58
getArray R5 , R6 , R7
PUSH R5
LoadS R5,K70
DoInvoke 2,4,R5
getGlobal R5,G5
PUSH R5
getGlobal R7,G15
getGlobal R8,G16
getArray R6 , R7 , R8
LoadS R7,K59
getArray R5 , R6 , R7
PUSH R5
LoadS R5,K70
DoInvoke 2,4,R5
getGlobal R5,G6
PUSH R5
getGlobal R7,G15
getGlobal R8,G16
getArray R6 , R7 , R8
LoadS R7,K60
getArray R5 , R6 , R7
PUSH R5
LoadS R5,K70
DoInvoke 2,4,R5
getGlobal R5,G7
PUSH R5
getGlobal R7,G15
getGlobal R8,G16
getArray R6 , R7 , R8
LoadS R7,K61
getArray R5 , R6 , R7
PUSH R5
LoadS R5,K70
DoInvoke 2,4,R5
getGlobal R5,G8
PUSH R5
getGlobal R7,G15
getGlobal R8,G16
getArray R6 , R7 , R8
LoadS R7,K62
getArray R5 , R6 , R7
PUSH R5
LoadS R5,K70
DoInvoke 2,4,R5
getGlobal R5,G9
PUSH R5
getGlobal R7,G15
getGlobal R8,G16
getArray R6 , R7 , R8
LoadS R7,K63
getArray R5 , R6 , R7
PUSH R5
LoadS R5,K70
DoInvoke 2,4,R5
;end of if block
Jmp 0x000C78
;ELSE
DoCall 0,2,0,loadempty
;END IF
;end of if block
Jmp 0x000C84
;ELSE
DoCall 0,0,0,loadempty
;END IF
DoRet

NEWITEM:
PushNull 7
getGlobal R1,G17
LoadI R2,K53
DoAdd R0,R1,R2
setGlobal G17,R0
getGlobal R0,G17
setGlobal G16,R0
getGlobal R0,G17
getGlobal R2,G15
LoadS R3,K65
setArray R2 , R3 , R0
newArray R0
getGlobal R2,G15
getGlobal R3,G16
setArray R2 , R3 , R0
LoadS R1,K72
getGlobal R2,G16
DoAdd R0,R1,R2
getGlobal R3,G15
getGlobal R4,G16
getArray R2 , R3 , R4
LoadS R3,K54
setArray R2 , R3 , R0
LoadS R1,K73
getGlobal R2,G16
DoAdd R0,R1,R2
getGlobal R3,G15
getGlobal R4,G16
getArray R2 , R3 , R4
LoadS R3,K56
setArray R2 , R3 , R0
LoadS R1,K74
getGlobal R2,G16
DoAdd R0,R1,R2
getGlobal R3,G15
getGlobal R4,G16
getArray R2 , R3 , R4
LoadS R3,K57
setArray R2 , R3 , R0
LoadS R1,K75
getGlobal R2,G16
DoAdd R0,R1,R2
getGlobal R3,G15
getGlobal R4,G16
getArray R2 , R3 , R4
LoadS R3,K58
setArray R2 , R3 , R0
LoadS R1,K76
getGlobal R2,G16
DoAdd R0,R1,R2
getGlobal R3,G15
getGlobal R4,G16
getArray R2 , R3 , R4
LoadS R3,K59
setArray R2 , R3 , R0
LoadS R1,K77
getGlobal R2,G16
DoAdd R0,R1,R2
getGlobal R3,G15
getGlobal R4,G16
getArray R2 , R3 , R4
LoadS R3,K60
setArray R2 , R3 , R0
LoadS R1,K78
getGlobal R2,G16
DoAdd R0,R1,R2
getGlobal R3,G15
getGlobal R4,G16
getArray R2 , R3 , R4
LoadS R3,K61
setArray R2 , R3 , R0
LoadS R1,K79
getGlobal R2,G16
DoAdd R0,R1,R2
getGlobal R3,G15
getGlobal R4,G16
getArray R2 , R3 , R4
LoadS R3,K62
setArray R2 , R3 , R0
LoadS R1,K80
getGlobal R2,G16
DoAdd R0,R1,R2
getGlobal R3,G15
getGlobal R4,G16
getArray R2 , R3 , R4
LoadS R3,K63
setArray R2 , R3 , R0
DoRet

BTNADDCLICK:
PushNull 2
DoCall 0,1,0,savecurrent
DoCall 0,1,0,newitem
DoCall 0,1,0,savefile
DoCall 0,1,0,loadcurrent
DoRet

BTNREMOVECLICK:
PushNull 11

;if
getGlobal R2,G16
LoadI R3,K38
bA 1,R2,R3
Jmp 0x000EC0

;if
getGlobal R4,G16
getGlobal R5,G17
bLT 1,R4,R5
Jmp 0x000E78
.FOR_INIT:
getGlobal R1,G16
.FOR_COMPARE:
getGlobal R7,G17
LoadI R8,K53
DoSub R6,R7,R8
bA 0,R1,R6
Jmp 0x.FOR_END
getGlobal R8,G15
getGlobal R10,G16
LoadI R11,K53
DoAdd R9,R10,R11
getArray R7 , R8 , R9
getGlobal R9,G15
getGlobal R10,G16
setArray R9 , R10 , R7
LoadI R7,K53
DoAdd R1,R1,R7
Jmp 0x.FOR_COMPARE
.FOR_END:
;END IF
newArray R4
getGlobal R6,G15
getGlobal R7,G17
setArray R6 , R7 , R4
getGlobal R5,G17
LoadI R6,K53
DoSub R4,R5,R6
setGlobal G17,R4

;if
getGlobal R4,G16
getGlobal R5,G17
bA 1,R4,R5
Jmp 0x000EB0
getGlobal R6,G17
setGlobal G16,R6
;END IF
getGlobal R4,G17
getGlobal R6,G15
LoadS R7,K65
setArray R6 , R7 , R4
;END IF
DoCall 0,2,0,savefile
DoCall 0,2,0,loadcurrent
DoRet

BTNPREVCLICK:
PushNull 8
DoCall 0,1,0,savefile
LoadS R2,K81
PUSH R2
LoadS R2,K51
DoInvoke 1,1,R2

;if
getGlobal R1,G17
LoadI R2,K38
bA 1,R1,R2
Jmp 0x000F2C

;if
getGlobal R3,G16
LoadI R4,K53
bA 1,R3,R4
Jmp 0x000F24
getGlobal R6,G16
LoadI R7,K53
DoSub R5,R6,R7
setGlobal G16,R5
;end of if block
Jmp 0x000F2C
;ELSE
getGlobal R3,G17
setGlobal G16,R3
;END IF
;END IF
LoadS R3,K82
getGlobal R4,G16
DoAdd R2,R3,R4
PUSH R2
LoadS R2,K51
DoInvoke 1,1,R2
DoCall 0,1,0,loadcurrent
DoRet

BTNNEXTCLICK:
PushNull 8
DoCall 0,1,0,savefile

;if
getGlobal R1,G17
LoadI R2,K38
bA 1,R1,R2
Jmp 0x000F98

;if
getGlobal R3,G16
getGlobal R4,G17
bLT 1,R3,R4
Jmp 0x000F90
getGlobal R6,G16
LoadI R7,K53
DoAdd R5,R6,R7
setGlobal G16,R5
;end of if block
Jmp 0x000F98
;ELSE
LoadI R3,K53
setGlobal G16,R3
;END IF
;END IF
DoCall 0,1,0,loadcurrent
DoRet
Constants:
	.K0 dd 10
	.K1 dd 350
	.K2 dd 435
	.K3 dd Strings.S0
	.K4 dd Strings.S1
	.K5 dd 310
	.K6 dd 16
	.K7 dd Strings.S2
	.K8 dd Strings.S3
	.K9 dd 30
	.K10 dd 330
	.K11 dd 25
	.K12 dd Strings.S4
	.K13 dd 65
	.K14 dd Strings.S5
	.K15 dd 85
	.K16 dd 120
	.K17 dd 250
	.K18 dd Strings.S6
	.K19 dd 140
	.K20 dd 270
	.K21 dd 70
	.K22 dd Strings.S7
	.K23 dd 175
	.K24 dd Strings.S8
	.K25 dd 195
	.K26 dd 90
	.K27 dd Strings.S9
	.K28 dd 230
	.K29 dd Strings.S10
	.K30 dd 285
	.K31 dd Strings.S11
	.K32 dd 305
	.K33 dd 340
	.K34 dd Strings.S12
	.K35 dd 360
	.K36 dd 395
	.K37 dd Strings.S13
	.K38 dd 0
	.K39 dd 3600
	.K40 dd Strings.S14
	.K41 dd 50
	.K42 dd Strings.S15
	.K43 dd 3796
	.K44 dd Strings.S16
	.K45 dd 3920
	.K46 dd Strings.S17
	.K47 dd 3560
	.K48 dd Strings.S18
	.K49 dd Strings.S19
	.K50 dd Strings.S20
	.K51 dd Strings.S21
	.K52 dd Strings.S22
	.K53 dd 1
	.K54 dd Strings.S23
	.K55 dd Strings.S24
	.K56 dd Strings.S25
	.K57 dd Strings.S26
	.K58 dd Strings.S27
	.K59 dd Strings.S28
	.K60 dd Strings.S29
	.K61 dd Strings.S30
	.K62 dd Strings.S31
	.K63 dd Strings.S32
	.K64 dd Strings.S33
	.K65 dd Strings.S34
	.K66 dd Strings.S35
	.K67 dd Strings.S36
	.K68 dd Strings.S37
	.K69 dd Strings.S38
	.K70 dd Strings.S39
	.K71 dd Strings.S40
	.K72 dd Strings.S41
	.K73 dd Strings.S42
	.K74 dd Strings.S43
	.K75 dd Strings.S44
	.K76 dd Strings.S45
	.K77 dd Strings.S46
	.K78 dd Strings.S47
	.K79 dd Strings.S48
	.K80 dd Strings.S49
	.K81 dd Strings.S50
	.K82 dd Strings.S51
Strings:
	.S db "Address book",0
	.S db "WINDOW.CREATE",0
	.S db "First name : ",0
	.S db "TEXTBLOC.CREATE",0
	.S db "TEXTBOX.CREATE",0
	.S db "Last name : ",0
	.S db "Street : ",0
	.S db "Number : ",0
	.S db "Zip : ",0
	.S db "City : ",0
	.S db "Country : ",0
	.S db "Phone : ",0
	.S db "E-Mail : ",0
	.S db "-",0
	.S db "BUTTON.CREATE",0
	.S db "<",0
	.S db ">",0
	.S db "+",0
	.S db "contact.dat",0
	.S db "IO.OPENFILE",0
	.S db "test input file",0
	.S db "KWRITELINE",0
	.S db "IO.EOF",0
	.S db "firstname",0
	.S db "IO.READLINE",0
	.S db "lastname",0
	.S db "street",0
	.S db "streetnum",0
	.S db "zip",0
	.S db "city",0
	.S db "country",0
	.S db "phone",0
	.S db "mail",0
	.S db "finished reading",0
	.S db "count",0
	.S db "IO.CLOSEFILE",0
	.S db "IO.FLUSHFILE",0
	.S db "IO.WRITELINE",0
	.S db "",0
	.S db "TEXTBOX.SETTEXT",0
	.S db "TEXTBOX.GETTEXT",0
	.S db "first name ",0
	.S db "last name ",0
	.S db "street ",0
	.S db "N ",0
	.S db "zip ",0
	.S db "city ",0
	.S db "country ",0
	.S db "phone ",0
	.S db "mail ",0
	.S db "prev clicked",0
	.S db "new index : ",0
