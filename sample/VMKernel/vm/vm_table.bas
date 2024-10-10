#include once "vm_table.bi"
constructor VM_TABLE_NODE()
    MAGIC       = VM_TABLE_NODE_MAGIC
    NextNode    = 0
    PrevNode    = 0
    
    KEY.vType   = VM_ValueType.VMNull
    KEY.vValue  = 0
    VALUE.vType   = VM_ValueType.VMNull
    VALUE.vValue  = 0
end constructor

destructor VM_TABLE_NODE()
    'kwriteline(@"Table node deleted")
    if (MAGIC = VM_TABLE_NODE_MAGIC) then
        Key.SetNull()
        Value.SetNull()
        MAGIC           = 0
        NextNode        = 0
        PrevNode        = 0
    end if
end destructor


constructor VM_TABLE()
    FirstNode       = 0
    LastNode        = 0
    MAGIC2          = VM_TABLE_MAGIC
    DestroyMethod   = cptr(any ptr,@DestroyVMTable)
    VisitMethod     = cptr(any ptr,@ VisitVMTable)
end constructor

destructor VM_TABLE()
   ' kwriteline(@"Table deleted")
    if (MAGIC2 = VM_TABLE_MAGIC) then
        var node = FirstNode
        while node<>0
            var n = node->NextNode
            delete node
            node = n
        wend
        FirstNode       = 0
        LastNode        = 0
        MAGIC2          = 0
        DestroyMethod   = 0
    end if
end destructor

constructor VM_CLASS_INSTANCE(c as VM_CONTEXT ptr,owner as VM_CONTEXT ptr)
   ' KWrite(@"Create new instance of ")
    KWriteLine(c->ClassName->Buffer)
    OWNER           = owner
    MAGIC2          = VM_INSTANCE_MAGIC
    CLASS_CONTEXT   = c
    FIELDSCOUNT     = c->FieldsCount
    if (FIELDSCOUNT>0) then
        FIELDS      = allocate(sizeof(VM_KEY_VALUE_PAIR)*FIELDSCOUNT)
        for i as integer = 0 to FIELDSCOUNT-1
            FIELDS[i].Key.vType     = VM_ValueType.VMNull
            FIELDS[i].Key.vValue    = 0
            FIELDS[i].Value.vType     = VM_ValueType.VMNull
            FIELDS[i].Value.vValue    = 0
            
            FIELDS[i].Key.SetString(@c->FIELDS[i])
            
            KWrite(@"Field initialized to null : ")
            FIELDS[i].KEY.PrintValue()
            KWRITELIne(@"")
        next
        c->Add_GC(@this)
    else
        FIELDS      = 0
    end if
end constructor

destructor VM_CLASS_INSTANCE()
    if (FIELDS=0) then
        for i as integer = 0 to FIELDSCOUNT-1
            FIELDS[i].Key.SetNull()
            FIELDS[i].Value.SetNull()
        next i
        deallocate(FIELDS)
    end if
    FIELDS      = 0
    FIELDSCOUNT = 0
end destructor


sub VM_CLASS_INSTANCE.SetValue(k as VM_BOXEDVALUE ptr,v as VM_BOXEDVALUE ptr)
    if (FIELDSCOUNT>0) then
        for i as integer = 0 to FIELDSCOUNT-1
            if (VM_BoxedValue.Equals(@FIELDS[i].KEY,k)) then
                FIELDS[i].Value.SetBoxed(v)
                return
            end if
        next
    end if
end sub

function VM_CLASS_INSTANCE.GetValue(k as VM_BOXEDVALUE ptr) as VM_BOXEDVALUE ptr
    if (FIELDSCOUNT>0) then
        for i as integer = 0 to FIELDSCOUNT-1
            if (VM_BoxedValue.Equals(@FIELDS[i].KEY,k)) then
                return @FIELDS[i].Value
            end if
        next
    end if
    return 0
end function




sub VM_TABLE.AddNode(item as VM_TABLE_NODE ptr)
    item->PrevNode = this.LastNode
    item->NextNode = 0
    if (this.LastNode<>0) then
        this.LastNode->NextNode = item
    else 
        this.FirstNode=item
    end if
    this.LastNode = item
end sub

sub VM_TABLE.RemoveNode(item as VM_TABLE_NODE ptr)
    if (item->PrevNode<>0) then
        item->PrevNode->NextNode = item->NextNode
    else
        FirstNode = item->NextNode
    end if
    if (item->NextNode<>0) then
        item->NextNode->PrevNode = item->PrevNode
    else
        LastNode=item->PrevNode
    end if
end sub

function VM_TABLE.SetValue(key as VM_BoxedValue ptr,value as VM_BoxedValue ptr) as integer
    var node = this.FirstNode
    while node<>0
        if (VM_BoxedValue.Equals(@node->Key,key)) then
            if (value->vType = VM_ValueType.VMNull) then
                this.RemoveNode(node)
                delete node
            else
                node->Value.SetBoxed(value)
            end if
            return 1
        end if
        node = node->NextNode
    wend
    node = new VM_TABLE_NODE()
    node->Key.SetBoxed(key)
    node->Value.SetBoxed(value)
    this.AddNode(node)
    return 1
end function

function VM_TABLE.GetValue(key as VM_BoxedValue ptr) as VM_BoxedValue ptr
    var node = this.FirstNode
    while node<>0
        if (VM_BoxedValue.Equals(@node->Key,key)) then
           return @node->Value
        end if
        node = node->NextNode
    wend
    return 0
end function

sub VisitVMTable(tbl as VM_Table ptr)
    var node = tbl->FirstNode
    while node<>0
        node->Key.Visit()
        node->Value.Visit()
        node = node->NextNode
    wend
end sub


sub DestroyVMTable(tbl as VM_TABLE ptr)
    tbl->destructor()
end sub

sub DestroyVMInstance(inst as VM_CLASS_INSTANCE ptr)
    inst->destructor()
end sub