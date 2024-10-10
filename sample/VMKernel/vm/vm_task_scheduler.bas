dim shared VM_FirstTask    as VM_TASK ptr
dim shared VM_LastTask     as VM_TASK ptr 
dim shared VM_CurrentTask  as VM_TASK ptr

dim shared VM_TaskToAdd     as VM_TASK ptr
dim shared VM_CTXToRemove   as VM_Context ptr
sub VM_TaskScheduler.Init()
    VM_FirstTask    = 0
    VM_LastTask     = 0 
    VM_CurrentTask  = 0
    VM_TaskToAdd    = 0
    VM_CTXToRemove  = 0 
end sub

sub VM_AddTask(t as VM_TASK ptr)
    VM_TaskToAdd =  t
end sub

sub VM_ENDAPP(t as VM_CONTEXT ptr)
    VM_CTXToRemove = t
end sub


sub VM_TaskScheduler.AddHead(t as VM_Task ptr)
    t->NextTaskQueue = VM_FirstTask
    t->PrevTaskQueue = 0
    
    if (VM_FirstTask <> 0) then VM_FirstTask->PrevTaskQueue = t
    if (VM_LastTask = 0)   then VM_LastTask = t
    
    VM_FirstTask = t
end sub

sub VM_TaskScheduler.AddTail(t as VM_Task ptr)
    t->NextTaskQueue = 0
    t->PrevTaskQueue = VM_LastTask
    
    if (VM_LastTask <>0)  then VM_LastTask->NextTaskQueue = t
    if (VM_FirstTask = 0) then VM_FirstTask = t
    
    VM_LastTask = t
end sub

sub VM_TaskScheduler.RemoveTask(t as VM_Task ptr)
    if (t->PrevTaskQueue<>0) then
        t->PrevTaskQueue->NextTaskQueue = t->NextTaskQueue
    else
        VM_FirstTask = t->NextTaskQueue
    end if
    if (t->NextTaskQueue<>0) then
        t->NextTaskQueue->PrevTaskQueue = t->PrevTaskQueue
    else
        VM_LastTask = t->PrevTaskQueue
    end if
    t->NextTaskQueue = 0
    t->PrevTaskQueue = 0
end sub

function VM_TaskScheduler.Dequeue() as VM_Task ptr
    dim t as VM_Task ptr = VM_FirstTask
    if (t<>0) then
        VM_FirstTask = t->NextTaskQueue
        if (VM_FirstTask = 0) then VM_LastTask = 0
        t->NextTaskQueue = 0
        t->PrevTaskQueue = 0
    end if
    return t
end function

sub VM_TaskScheduler.Schedule()
    var ctask = VM_CurrentTask
    if (ctask<>0) then
        if (ctask->Terminated) then
            ctask 			= 0
			VM_CurrentTask	= 0
        end if
    end if
    
    if (ctask<>VM_FirstTask and VM_FirstTask<>0) then
        if (ctask<>0) then VM_TaskScheduler.AddTail(ctask)
        VM_CurrentTask = VM_TaskScheduler.Dequeue()
    end if
end sub


sub VM_TaskScheduler_EndApp()
     if (VM_CTXToRemove<>0) then
        
         var ctx = VM_CTXToRemove
         VM_CTXToRemove = 0
         var t = VM_FirstTask
         while t<>0
            var n = t->NextTaskQueue
            if (t->CurrentContext = ctx or t->StartContext = ctx) then
                VM_TaskScheduler.RemoveTask(t)
                ctx->RemoveTask(t)
                delete t
            end if
            
            t = n
        wend
        if (VM_CurrentTask<>0) then
            if (VM_CurrentTask->StartContext=ctx) then
                ctx->RemoveTask(VM_CurrentTask)
                delete VM_CurrentTask
                VM_CurrentTask = 0
            end if
        end if
        
        t = ctx->FirstTask
        while t<>0
            var n = t->NextTaskContext
            ctx->RemoveTask(t)
            delete t
            t = n
        wend
        
        'removing references
        if (ctx->GlobalVarCount>0) then
            for i as integer = 0 to ctx->GlobalVarCount-1
                ctx->GlobalVars[i].SetNull()
            next
        end if
        
       
        ctx->Collect()
        ctx->ShowRefs()
        
        delete ctx
    end if
end sub


sub VM_TaskScheduler_Run cdecl alias "vm_taskscheduler_run"()
    
    
    'KWriteLine(@"Task scheduler started")
    'do
		'VM_TaskScheduler.Schedule()
        VM_TaskScheduler_EndApp()
            
		if (VM_TaskToAdd<>0) then
            VM_TaskScheduler.AddHead(VM_TaskToAdd)
            VM_TaskToAdd=0
        end if
        
        
        if (VM_CurrentTask<>0) then
            if (VM_CurrentTask->Terminated) then 
                
                VM_CurrentTask = VM_TaskScheduler.Dequeue()
            else
                VM_TaskScheduler.AddTail(VM_CurrentTask)
                VM_CurrentTask = VM_TaskScheduler.Dequeue()
           end if
        else
            VM_CurrentTask = VM_TaskScheduler.Dequeue()
        end if
        
        
        
        if (VM_CurrentTask<>0) then
            
            var task = VM_CurrentTask
            dim context as VM_CONTEXT ptr = task->CurrentContext
            
            
            
            dim instruction as VM_INSTRUCTION PTR= cptr(VM_INSTRUCTION ptr,cuint(context->Memory)+cuint(task->IP))
            task->IP+= sizeof(VM_INSTRUCTION)
            select case instruction->OPCODE
                case VM_OPCode.NOP:
                case VM_OPCode.PUSH:
                     Task->MainStack.Push(Task->Regs(instruction->DESTREG))
                case VM_OPCode.POP
                    Task->Regs(instruction->DESTREG)->SetBoxed(task->MainStack.Pop())
                case VM_OPCode.PUSHNULL:
                    for i as integer = 1 to instruction->DESTREG
                        task->MainStack.PushNull()
                    next
                case VM_OPCode.LOADN:
                    Task->Regs(instruction->DestReg)->SetNull()
                case VM_OPCode.LoadB:
                    Task->Regs(instruction->DestReg)->SetBoolean(instruction->SRCREG1)
                case VM_OPCode.LoadI:	
                    dim kint as longint = cptr(longint ptr,context->constTable)[instruction->SRCREG1]
                    Task->Regs(instruction->DESTREG)->SetInteger(kint)
                case VM_OPCode.LoadR:
                   dim kreal as double = cptr(double ptr,context->constTable)[instruction->SRCREG1]
                   Task->Regs(instruction->DESTREG)->SetReal(kreal)
                case VM_OPCode.LoadA:
                    dim kuint as unsigned longint = cptr(unsigned longint ptr,context->constTable)[instruction->SRCREG1]
                    Task->Regs(instruction->DESTREG)->SetFunction(kuint)
                case VM_OPCode.LoadS:
                    dim kuint as unsigned longint = cptr(unsigned longint ptr,context->constTable)[instruction->SRCREG1]
                    var vs = VM_STRING.Create(task->StartContext, cptr(unsigned byte ptr,cuint(kuint)+cuint(context->Memory)))
                    Task->Regs(instruction->DESTREG)->SetString(vs)
                case VM_OPCode.LoadRandom:
                    var _min = Task->Regs(instruction->SrcReg1)->GetInteger()
                    var _max = Task->Regs(instruction->SrcReg2)->GetInteger()
                    Task->Regs(instruction->DestReg)->SetInteger(get_random(_min,_max))
                case VM_OPCode.DoAdd:
                    vm_BoxedValue.DoAdd(context,Task->Regs(instruction->DESTREG), Task->Regs(instruction->SRCREG1),Task->Regs(instruction->SRCREG2))
                case VM_OPCode.DoSub:
                    vm_BoxedValue.DoSub(context,Task->Regs(instruction->DESTREG), Task->Regs(instruction->SRCREG1),Task->Regs(instruction->SRCREG2))
                case VM_OPCode.DoMul:
                    vm_BoxedValue.DoMul(context,Task->Regs(instruction->DESTREG), Task->Regs(instruction->SRCREG1),Task->Regs(instruction->SRCREG2))
                case VM_OPCode.DoDIV:
                    vm_BoxedValue.DoDiv(context,Task->Regs(instruction->DESTREG), Task->Regs(instruction->SRCREG1),Task->Regs(instruction->SRCREG2))
                case VM_OPCode.DoInc:
                    vm_BoxedValue.DoInc(context,Task->Regs(instruction->DESTREG), Task->Regs(instruction->SRCREG1))
                case VM_OPCode.DoDec:
                    vm_BoxedValue.DoDec(context,Task->Regs(instruction->DESTREG), Task->Regs(instruction->SRCREG1))
                case VM_OPCode.MovReg:
                    Task->Regs(instruction->DESTREG)->SetBoxed(task->Regs(instruction->SRCREG1))
                case VM_OPCode.LoadVar:
                case VM_OPCode.StorVar:
                case VM_OPCode.DoInvoke:
                    var ok = 0
                    var xresult = Task->Regs(instruction->SRCREG1)
                    If (Task->Regs(instruction->SRCREG2)->vType = VM_VALUETYPE.vmSTRING) then
                        var vs = cptr(VM_STRING ptr,cuint(Task->Regs(instruction->SRCREG2)->vValue))
                        var method = VM_MANAGER_FIND_METHOD_BY_HASH(vs->HASH)
                        if (method<>0) then
                            
                            if (method->NATIVE_PTR<>0) then
                                dim pcount as unsigned integer = instruction->DestReg
                                
                                dim position as integer = Task->MainStack.Position-pcount
                                method->NATIVE_PTR(context,@Task->MainStack.Values(Task->MainStack.Position-pcount),xresult)
                                
                                
                                for i as integer = position to Task->MainStack.Position
                                    Task->MainStack.Values(i).SetNull()
                                next
                                Task->MainStack.Position = Task->MainStack.Position-pcount
                            else
                                Task->CallStack.Push(Task->IP,task->RegBase,context,xresult)
                                Task->RegBase           = Task->MainStack.Position - instruction->DestReg
                                Task->IP                = Method->VM_PTR
                                Task->CurrentContext    = Method->VM_CTX
                            end if
                        end if
                    end if
                case VM_OPCode.DoCall:
                    var xresult     = Task->Regs(instruction->SRCREG1)
                    var destAddr    = instruction->Value
                    Task->CallStack.Push(Task->ip,task->RegBase,context,xresult)
                    Task->RegBase   = Task->MainStack.Position - instruction->DestReg
                    Task->IP        = DestAddr
                case VM_OPCode.DoJumP
                    Task->IP        = instruction->LOW24
                case VM_OPCode.DoRet:
                    dim X0 as VM_BoxedValue ptr = Task->Regs(0)  
                    dim position as integer = Task->RegBase+1
                    for i as integer = position to Task->MainStack.Position
                        Task->MainStack.Values(i).SetNull()
                    next
                    
                    Task->MainStack.Position    = Task->RegBase
                    
                    if (task->CallStack.CanPop()) then
                        var frame = Task->CallStack.Pop()
                        Task->RegBase           = frame->RegBase
                        Task->CurrentContext    = frame->CTX
                        Task->IP                = frame->IP
                        frame->DestReg->SetBoxed(X0)
                    else
                        kwriteline(@"ending task")
                        var ctx=task->StartContext
                        ctx->RemoveTask(task)
                        delete task
                        VM_CurrentTask = 0
                        ctx->Collect()
                    end if
                 case VM_OPCode.CMPE:
                    if (VM_BoxedValue.Equals(_
                            Task->Regs(instruction->SRCREG1), _
                            Task->Regs(instruction->SRCREG2) _
                        ) = (instruction->DESTREG<>0) ) then
                        TASK->IP+=sizeof(VM_INSTRUCTION)
                    end if
                 case VM_OPCode.CMPA:
                    if (instruction->DESTREG<>0) = (Task->Regs(instruction->SRCREG1)->GetInteger()>Task->Regs(instruction->SRCREG2)->GetInteger()) then
                        Task->IP+=sizeof(VM_INSTRUCTION)
                    end if
                 case VM_OPCode.CMPB:
                    if (instruction->DESTREG<>0) = (Task->Regs(instruction->SRCREG1)->GetInteger()<Task->Regs(instruction->SRCREG2)->GetInteger()) then
                        Task->IP+=sizeof(VM_INSTRUCTION)
                    end if
                case VM_OPCode.CMPTRUE:
                    if (instruction->DESTREG<>0) = (Task->Regs(instruction->SRCREG1)->GetInteger()<>0) then
                        Task->IP+=sizeof(VM_INSTRUCTION)
                    end if
                case VM_OPCode.getGlobal:
                    if (instruction->SRCREG1>=0 and instruction->SRCREG1<context->GlobalVarCount) then
                        Task->Regs(instruction->DESTREG)->SetBoxed(@context->GlobalVars[instruction->SRCREG1])
                    end if
                case VM_OPCode.setGlobal:
                    if (instruction->DESTREG>=0 and instruction->DESTREG<context->GlobalVarCount) then
                        context->GlobalVars[instruction->DESTREG].SetBoxed(Task->Regs(instruction->SRCREG1))
                    end if
                case VM_OPCode.setField
                    if (Task->Regs(instruction->DESTREG)->vType = VM_ValueType.vmObj) then
                        if (Task->Regs(instruction->SRCREG1)->vType = VM_ValueType.vmString) then
                            var objInstance = cptr(VM_CLASS_INSTANCE ptr,cuint(Task->Regs(instruction->DESTREG)->vValue))
                            var fieldKey    = cptr(VM_STRING ptr,cuint(Task->Regs(instruction->SRCREG1)->vValue))
                            objInstance->SetValue(Task->Regs(instruction->SRCREG1),Task->Regs(instruction->SRCREG2))
                        end if
                    end if
                case VM_OPCode.getField
                    if (Task->Regs(instruction->SRCREG1)->vType = VM_ValueType.vmObj) then
                        if (Task->Regs(instruction->SRCREG2)->vType = VM_ValueType.vmString) then
                            var objInstance = cptr(VM_CLASS_INSTANCE ptr,cuint(Task->Regs(instruction->SRCREG1)->vValue))
                            var fieldKey    = cptr(VM_STRING ptr,cuint(Task->Regs(instruction->SRCREG2)->vValue))
                            var v = objInstance->GetValue(Task->Regs(instruction->SRCREG2))
                            if (v<>0) then
                                Task->Regs(instruction->DESTREG)->SetBoxed(v)
                            end if
                        end if
                    end if
                case VM_OPCode.newArray
                    var tbl = new VM_TABLE()
                    Task->Regs(instruction->DESTREG)->SetPtr(VM_ValueType.vmTABLE, tbl)
                    Task->StartContext->ADD_GC(tbl)
                case VM_OPCode.setArray
                    if (Task->Regs(instruction->DESTREG)->vType = VM_ValueType.vmTABLE) then
                        dim tbl as VM_Table ptr = Task->Regs(instruction->DESTREG)->GetPtr()
                        if (tbl<>0) then
                            if (tbl->MAGIC2 = VM_TABLE_MAGIC) then
                                tbl->SetValue(Task->Regs(instruction->SRCREG1),Task->Regs(instruction->SRCREG2))
                            end if
                        end if
                    end if
                case VM_OPCode.getArray
                    if (Task->Regs(instruction->SRCREG1)->vType = VM_ValueType.vmTABLE) then
                        dim tbl as VM_Table ptr = Task->Regs(instruction->SRCREG1)->GetPtr()
                        if (tbl<>0) then
                            if (tbl->MAGIC2 = VM_TABLE_MAGIC) then
                                 Task->Regs(instruction->DESTREG)->SetBoxed( tbl->GetValue(Task->Regs(instruction->SRCREG2)))
                            end if
                        end if
                    end if
                case else
            end select
        end if
    'loop
end sub