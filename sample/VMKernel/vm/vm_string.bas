#include once "vm_string.bi"

function VM_String.Create(ctx as any ptr,b as unsigned byte ptr) as VM_String ptr
    var slen = strlen(b)
    var hash = StringHash(b,slen)
    dim s as VM_String ptr
    
    'search in the pool of strings
    if (ctx<>0) then
        s = cptr(VM_CONTEXT PTR,ctx)->GET_FIRST_STRING()
        while s<>0
            if (s->MAGIC2 = VM_STRING_MAGIC) then
                if s->HASH = hash then return s
            end if
            s=s->NextString
        wend
    end if
    s =  new VM_String(ctx,b,slen,hash)
    return s
end function

constructor VM_String(ctx as any PTR, b as unsigned byte ptr,slen as unsigned integer,h as unsigned longint)
    MAGIC2      = VM_STRING_MAGIC
    STRINGLEN   = slen
    BUFFER      = allocate(slen+1)
    strcpy(BUFFER,b)
    HASH        = h
    DestroyMethod = cptr(any ptr,@DestroyVMString)
    if (ctx<>0) then
        cptr(VM_CONTEXT ptr,ctx)->Add_String(@this)
    end if
end constructor

constructor VM_String(ctx as any ptr,b as unsigned byte ptr)
    MAGIC2      = VM_STRING_MAGIC
    STRINGLEN   = strlen(b)
    BUFFER      = allocate(STRINGLEN+1)
    strcpy(BUFFER,b)
    HASH        = StringHash(BUFFER,STRINGLEN)
    DestroyMethod = cptr(any ptr,@DestroyVMString)
    
    if (ctx<>0) then
        cptr(VM_CONTEXT ptr,ctx)->Add_String(@this)
    end if
end constructor

destructor VM_String()
    if (MAGIC2      = VM_STRING_MAGIC) then
        MAGIC2      = 0
        if (BUFFER<>0) then deallocate(BUFFER)
        BUFFER      = 0
        STRINGLEN   = 0
        HASH        = 0
    end if
end destructor

sub DestroyVMString(s as VM_String ptr)
    s->destructor()
end sub

function VM_String.Equals(other as VM_String ptr) as integer
    if (other = 0) then return 0
    if (other->MAGIC2 <> VM_STRING_MAGIC) then return 0
    if (other = @this) then return 1
    if (other->HASH = HASH) then return 1
    return 0
end function

function VM_String.CompareTo(other as VM_STRING ptr) as integer
    if (other = 0) then return -1
    
    'its the same objects
    if (other = @this) then return 0
    
    if (other->MAGIC2 = VM_STRING_MAGIC) then
        'its the same hash value
        if (other->HASH = HASH) then return 0
        
        return strcmp(BUFFER,OTHER->BUFFER)
    end if
    return -1
end function