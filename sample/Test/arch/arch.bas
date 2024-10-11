

sub ARCH_SPINLOCK(p as integer ptr)
    'asm
    '    mov ecx,[p]
    '    .acquire:
        
    '    lock bts dword ptr [ecx],0
    '    jnc .acquired
    '    .retest:
        
    '        pause
    '        test dword ptr [ecx],1
    '        je .retest
            
    '        lock bts dword ptr [ecx],0
    '        jc .retest
            
    '    .acquired:
    'end asm
end sub

sub ARCH_UNLOCK(p as integer ptr)
    '*p = 0
end sub
