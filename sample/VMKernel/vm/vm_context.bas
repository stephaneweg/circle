#include once "vm_context.bi"
#include once "vm_opcodes.bi"

type VM_HEADER field = 1
    MAGIC as unsigned long
	ENTRY as unsigned long
	CONSTANT_TABLE as unsigned long
    GLOBAL_COUNT as unsigned long
end type

type VM_CLASS_ENTRY field=1
    ClassName   as unsigned long
    MethodCount as unsigned long
    FieldCount  as unsigned long
    MethodTable as unsigned long
    FieldTable  as unsigned long
end type

type VM_METHOD_ENTRY field =1
    MethodName as unsigned long
    MethodAddr as unsigned long
end type

constructor VM_Context()
    ClassName       = 0
    FieldsCount     = 0
    Fields          = 0
    PrevContext     = 0
    NextContext     = 0
    
    
    FirstTask               = 0
    LastTask                = 0
    VM_STRING_COUNT         = 0
    VM_GC_COUNT             = 0
    VM_First_GC             = 0
    VM_Last_GC              = 0
    VM_FIRST_STRING         = 0
    VM_Last_STRING          = 0	 
end constructor

destructor VM_Context()
    if (GlobalVars<>0) then
        for i as integer = 0 to GlobalVarCount-1
            GlobalVars[i].SetNull()
        next i
        deallocate(GlobalVars)
    end if
    GlobalVars = 0
    GlobalVarCount = 0
    
    
    deallocate Memory
end destructor


#define VM_EXEC_MAGIC &hAABBCCDD
#define VM_CLASS_MAGIC &h11223344


sub VM_CONTEXT.AddTask(t as any ptr)
    var task = cptr(VM_TASK ptr,t)
    
    task->NextTaskContext = 0
    task->PrevTaskContext = FirstTask
    
    if (LastTask <>0)   then cptr(VM_TASK ptr,LastTask)->NextTaskContext = t
    if (FirstTask = 0)  then FirstTask = t
    
    LastTask = t
end sub

sub VM_CONTEXT.RemoveTask(t as any ptr)
    var task = cptr(VM_TASK ptr,t)
    
    if (task->PrevTaskContext<>0) then
        task->PrevTaskContext->NextTaskContext = task->NextTaskContext
    else
        FirstTask = task->NextTaskContext
    end if
    if (task->NextTaskContext<>0) then
        task->NextTaskContext->PrevTaskContext = task->PrevTaskContext
    else
        LastTask = task->PrevTaskContext
    end if
    
    task->NextTaskContext = 0
    task->PrevTaskContext = 0
end sub

function VM_Context.LoadFile(path as unsigned byte ptr) as  VM_Context ptr
    KWrite(@"Loading file : "):KWrite(path):KWriteLine(@" ... ")
	dim fsize as unsigned long = 0
	dim buff as unsigned byte ptr = VFS_LOAD_FILE(path,@fsize)
	if (buff<>0 and fsize>0) then
		var ctx = new VM_Context()
		
		ctx->MemorySize = fsize
		ctx->Memory = buff
        var header = cptr(VM_HEADER ptr,ctx->Memory)
		KWriteLine(@"success")
		
		ctx->Entry  		= header->ENTRY
		ctx->ConstTable	= cptr(longint ptr,cuint(header->CONSTANT_TABLE) + cuint(ctx->Memory))
		
		KWrite(@"Image loaded at        : 0x")
		KWriteLine(UIntToStr(cuint(ctx->Memory),16))
		
		KWrite(@"Image size : ")
		KWriteLine(UIntToStr(ctx->MemorySize,10))
		
		KWrite(@"Entry address          : 0x")
		KWriteLine(UIntToStr(ctx->Entry,16))
		
		KWrite(@"Constant table address : 0x")
		KWriteLine(UIntToStr(header->CONSTANT_TABLE,16))
        
        KWrite(@"Global variables count : ")
        KWriteLine(IntToStr(header->GLOBAL_COUNT,10))
        
        if (header->GLOBAL_COUNT>0) then
            ctx->GlobalVars = allocate(sizeof(VM_BoxedValue)*header->GLOBAL_COUNT)
            ctx->GlobalVarCount = header->GLOBAL_COUNT
            for i as integer =0 to ctx->GlobalVarCount-1
                ctx->GlobalVars[i].vType = VM_ValueType.vmNULL
                ctx->GlobalVars[i].vVALUE = 0
            next
        else
            ctx->GlobalVars      = 0
            ctx->GlobalVarCount  = 0
        end if
        
        if (header->MAGIC = VM_CLASS_MAGIC) then
            var class_header = cptr(VM_CLASS_ENTRY ptr,header->ENTRY+cuint(header))
            var clsName = cptr(unsigned byte ptr,class_header->ClassName+cuint(header))
            ctx->ClassName = VM_String.Create(0,clsName)
            KWrite(@ "Class Name : "):KWriteLine(ctx->ClassName->BUFFER)
            KWrite(@ "Methods Count : "):KWriteLine(UintToStr(class_header->MethodCount,10))
            KWrite(@ "Fields Count : "):KWriteLine(UintToStr(class_header->FieldCount,10))
            ctx->FieldsCount = class_header->FieldCount
            var method_Table = cptr(VM_METHOD_ENTRY ptr, (class_header->MethodTable+cuint(header)))
            for i as integer = 0 to class_header->MethodCount-1
                var methodName =cptr(unsigned byte ptr, method_table[i].MethodName+cuint(header))
                var methodAddr  = method_table[i].MethodAddr
                var fullName = strcat(strcat(ctx->ClassName->BUFFER,@"."),methodName)
                KWriteLine fullName
                var mname = VM_STRING.Create(0,fullName)
                var method = new VM_METHOD(mname,0,ctx,methodAddr)
                VM_MANAGER_ADD_METHOD(method)
            next
            
            if (ctx->FieldsCount>0) then
                ctx->Fields = allocate(sizeof(VM_STRING)*ctx->FieldsCount)
                var field_table = cptr(unsigned long ptr, (class_header->FieldTable+cuint(header)))
                for i as integer = 0 to ctx->FieldsCount-1
                    var fld = cptr(unsigned byte ptr, cuint(field_table[i])+cuint(header))
                    ctx->Fields[i].constructor(0,fld)
                    KWrite(@"FIELD : "):KWriteLine(ctx->Fields[i].Buffer)
                next
            end if
            VM_MANAGER_ADD_CLASS(ctx)
        end if
		return ctx
	end if
	return 0 
end function
