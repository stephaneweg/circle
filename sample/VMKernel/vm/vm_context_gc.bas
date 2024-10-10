
sub VM_CONTEXT.ShowRefs()
    var s = VM_FIRST_STRING
    while s<>0
        KWriteLine(s->Buffer )
        s=s->NextString
    wend
    
    var g = VM_FIRST_GC
    while g<>0
        KWrite(@"GC MAGIC 0x")
        KWrite(uintToStr(g->Magic2,16))
        KWrite(@" - Ptr = 0x")
        KWriteLine(UintToStr(cuint(g),16))
        g=>g->NextGC
    wend
end sub

function VM_CONTEXT.GET_FIRST_STRING() as VM_STRING ptr
    return VM_FIRST_STRING
end function


function VM_CONTEXT.FIND_STRING(item as VM_STRING ptr) as VM_STRING PTR
    var f = VM_FIRST_STRING
    while f<>0
        if (f=item) then return f
        f=f->NextString
    wend
    return 0
end function

function VM_CONTEXT.ADD_STRING(item as VM_String ptr) as integer
    if (item=0) then return 0
    if (item->MAGIC <> GC_MAGIC) then return 0
    if (item->MAGIC2 <> VM_STRING_MAGIC) then return 0
    if (item->ADDED <>0) then return 0
    if (FIND_STRING(item)=item) then
        return 0
    end if
    
    item->PrevString = VM_Last_STRING
    item->NextString = 0
    if (VM_Last_STRING<>0) then
        VM_Last_STRING->NextString = item
    else 
        VM_FIRST_STRING=item
    end if
    VM_Last_STRING = item
    item->ADDED = 1
    VM_STRING_COUNT+=1
    return 1
end function

function VM_CONTEXT.REMOVE_String(item as VM_String ptr) as integer
    
    if (item = 0) then return 0
    if (item->MAGIC<> GC_MAGIC) then return 0
    if (item->MAGIC2 <> VM_STRING_MAGIC) then return 0
    if (item->ADDED<>1) then return 0
    if (item->PrevString<>0) then
        item->PrevString->NextString = item->NextString
    else
        VM_FIRST_STRING = item->NextString
    end if
    if (item->NextString<>0) then
        item->NextString->PrevString = item->PrevString
    else
        VM_Last_STRING=item->PrevString
    end if
    item->ADDED = 0
    
    VM_STRING_COUNT-=1
    return 1
end function


function VM_CONTEXT.Add_GC(item as VM_GC ptr) as integer
    if (item=0) then return 0
    if (item->MAGIC <> GC_MAGIC) then return 0
    if (item->ADDED <>0) then return 0
    
    item->PrevGC = VM_Last_GC
    item->NextGC = 0
    if (VM_Last_GC<>0) then
        VM_Last_GC->NextGC = item
    else 
        VM_First_GC=item
    end if
    VM_Last_GC = item
    item->ADDED = 1
    VM_GC_COUNT += 1
    return 1
end function

function VM_CONTEXT.Remove_GC(item as VM_GC ptr) as integer
    if (item = 0) then return 0
    if (item->MAGIC<> GC_MAGIC) then return 0
    if (item->ADDED<>1) then return 0
    
    if (item->PrevGC<>0) then
        item->PrevGC->NextGC = item->NextGC
    else
        VM_First_GC = item->NextGC
    end if
    if (item->NextGC<>0) then
        item->NextGC->PrevGC = item->PrevGC
    else
        VM_Last_GC=item->PrevGC
    end if
    item->ADDED = 0
    VM_GC_COUNT -= 1
    return 1
end function

sub VM_CONTEXT.Collect_GC(gc as VM_GC ptr)
    if (GC->DESTROYMETHOD<>0) then GC->DestroyMethod(gc)
    deallocate gc
end sub


sub VM_CONTEXT.Collect()
    var cptBefore = VM_STRING_COUNT + VM_GC_COUNT
    
    var gc = VM_FIRST_GC
    while gc<>0
        gc->VISITED = 0
        GC=GC->NextGC
    wend
    var s = VM_FIRST_STRING
    while s<>0
        s->VISITED = 0
        s = s->NextString
    wend
    
    var t = cptr(VM_TASK ptr,FirstTask)
    while t<>0
        kwriteline(@"Visiting task")
        if (t->Mainstack.Position>0) then
            for i as integer = 0 to t->MainStack.Position-1
                t->MainStack.Values(i).Visit()
            next i
        end if
        t=t->NextTaskContext
    wend
    
    if (GlobalVarCount>0) then
        for i as integer = 0 to GlobalVarCount-1
            GlobalVars[i].Visit()
        next
    end if
    
    
    gc = VM_FIRST_GC
    while gc<>0
        var n = GC->NextGC
        if (gc->VISITED = 0) then
            Remove_GC(gc)
            Collect_GC(gc)
        end if
        GC= n
    wend
    s = VM_FIRST_STRING
    while s<>0
        var n = s->NextString
        if (s->VISITED = 0) then
            Remove_String(s)
            delete s
        end if
        
        s = n
    wend
    
    var cptAfter = VM_STRING_COUNT + VM_GC_COUNT
    
    KWrite(@"GC COUNT BEFORE : ")
    KWriteLine(IntToStr(cptBefore,10))
    KWrite(@"GC COUNT After : ")
    KWriteLine(IntToStr(cptAfter,10))
end sub