#include once "system.bi"
#include once "runtime.bi"



sub runtime_init cdecl alias "runtime_init"()
	KWRITELine(@"Hello from runtime")
end sub