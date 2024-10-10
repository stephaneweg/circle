type VM_TaskScheduler field = 4
    test as integer
    declare static sub Init()
    
    declare static sub RemoveTask(t as VM_Task ptr)
    declare static sub AddHead(t as VM_Task ptr)
    declare static sub AddTail(t as VM_Task ptr)
    declare static function Dequeue() as VM_Task ptr
    declare static sub Schedule()
end type
declare sub VM_AddTask(t as VM_TASK ptr)
declare sub VM_ENDAPP(t as VM_CONTEXT ptr)
declare sub VM_TaskScheduler_Run cdecl alias "vm_taskscheduler_run"()
 