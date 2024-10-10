#include once "vm_method.bi"
declare sub VM_MANAGER_INIT()
declare sub VM_MANAGER_ShowRefs()
declare sub VM_MANAGER_ADD_CLASS(ctx as VM_CONTEXT ptr)
declare sub VM_MANAGER_ADD_METHOD(method as VM_METHOD ptr)
declare function VM_MANAGER_FIND_METHOD_BY_NAME(methodName as unsigned byte ptr) as VM_METHOD ptr
declare function VM_MANAGER_FIND_METHOD_BY_HASH(hash as unsigned longint) as VM_METHOD ptr
declare sub VM_MANAGER_REGISTER_METHOD(methodName as unsigned byte ptr,target as any ptr)

declare sub VM_MANAGER_APP_START(path as unsigned byte ptr)
