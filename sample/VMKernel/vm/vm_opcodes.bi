enum VM_OPCode
    NOP             'No operation
    PUSH            'Push R[src] to the stack
    POP             'pop from the stack to R[dst]
    PUSHNULL        'push null to the stack (reservation)
    
    LoadN           'load NULL      to R[dest]
    LoadB           'load bool      to R[dest]
    LoadI           'load integer   to R[dest]
    LoadR           'load Real      to R[dest]
    LoadA           'load address   to R[dest]
    LoadS           'load string   to R[dest]
    LoadRandom      'load random number
    
    DoAdd           'addition       : R[dest] = R[src1] + R[src2], if one is boolean, both are treated as boolean, and Logical OR is performed
    DoSub           'substraction   : R[dest] = R[src1] - R[src2], if one is boolean, both are treated as boolean, and Logical XOR is performed
    DoMul           'multiplication : R[dest] = R[src1] * R[src2], if one is boolean, both are treated as boolean, and Logicial AND is performed
    DoDiv           'division       : R[dest] = R[src1] / R[src2], if one is boolean, both are treaded as boolean, and Logical AND is performed
    DoInc           'increment      : R[dest] = R[src]+1 ; if source is boolean, it will put true (because false + 1 = true, true +1 = true
    DoDec           'decrement      : R[dest] = R[src]-1 ; if soruce is boolean, it will put source XOR 1 (see substraction)
    
    MovReg          'move register  : R[dest] = R[src]
    LoadVar         'load variable  : R[dest] = V[src]
    StorVar         'stor variable  : V[dest] = R[src]
    
    DoCall          'call a submethod
    DoRet           'return
    DoJump
    DoInvoke
    
    CMPE            'cmpe a,b,c,dst  compare if equal: if R[b]=R[c]=a PC=dest
    CMPA            'compare if above: if R[src1]>R[src2]=dst PC=dest
    CMPB            'compare if below: if R[src1]<R[src2]= PC=dest
    CMPTRUE         'if R[B] = a PC = dest
    
    getGlobal,
    setGlobal,

    newArray,
    getArray,
    setArray,
    
    getField,
    setField
end enum

TYPE VM_INSTRUCTION field = 1
    OPCODE  as unsigned byte
    DESTREG as unsigned byte        'destination register
    SRCREG1 as unsigned byte        'source register 1  , or byte 0 of immediate value
    SRCREG2 as unsigned byte        'source register 2  , or byte 1 of immediate value
    
    declare property VALUE() as unsigned long
    declare property VALUE(v as unsigned long)
    declare property LOW24() as unsigned integer
end type

property VM_INSTRUCTION.LOW24() as unsigned integer
    return (*cptr(unsigned integer ptr,cuint(@this)+1)) and &h00FFFFFF
end property

property VM_INSTRUCTION.VALUE() as unsigned long
    return *cptr(unsigned long ptr,cuint(@this)+4)
end property

property VM_INSTRUCTION.VALUE(v as unsigned long)
    *cptr(unsigned long ptr,cuint(@this)+4)=v
end property

    
'LoadI 0,5                               '10
'DoCall factorielle                      '9

'factorielle:
'IF N>1 then
'LoadI   1,1         'x1=1               '10
'CMPNA   0,1,.END    'if x0>x1 then      '11

'result = factorielle(N-1)*N
'PUSH  0         'push x0                '2
'DoDec 0         'x0=x0-1                '2
'DoCall factorielle                      '9
'POP   1         'pop x1                 '2
'MUL   0,0,1     'x0 = x0*x1             '4

'.END:            'end if                '1
'RET
'10 instructions 

