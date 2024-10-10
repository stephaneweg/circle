#include once "vm_boxedvalue.bi"
#include once "vm_boxedvaluestack.bi"
#include once "vm_gc.bi"
#include once "vm_string.bi"
#include once "vm_context.bi"
#include once "vm_task.bi"
#include once "vm_task_scheduler.bi"

#include once "vm_method.bi"
#include once "vm_table.bi"
#include once "vm_opcodes.bi"
#include once "vm_manager.bi"
declare sub vm_init cdecl alias "vm_init"()