#ifndef _system_h
#define _system_h

extern "C" void knewline();
extern "C" void kwrite(const char* txt);
extern "C" void kwriteLine(const char* txt);
extern "C" void kwriteFormat(const char* txt,...);
extern "C" void kwriteFormatLine(const char* txt,...);
extern "C" void kwriteFormatV(const char* txt,va_list Args);
extern "C" void kwriteFormatVLine(const char* txt,va_list Args);

extern "C" void* vfs_load_file(const TCHAR* path,u32 *fsize);
extern "C" void vfs_write_file(const TCHAR* path,void* buffer,u32 fsize);
extern "C" u32 get_random(u32 min,u32 max);

extern "C" s32 get_joypad_axis(u32 gamepad,u32 axis);
extern "C" u32 get_joypad_buttons(u32 gamepad);


extern "C" void MemCpy64(u64* _dst, u64* _src, u32 _count);
extern "C" void MemCpy32(u32* _dst, u32* _src, u32 _count);
extern "C" void MemCpy16(u16* _dst, u16* _src, u32 _count);
extern "C" void MemCpy8(u8* _dst, u8* _src, u32 _count);

extern "C" void MemSet64(u64* _dst,u64 _value,u32 _count);
extern "C" void MemSet32(u32* _dst,u32 _value,u32 _count);
extern "C" void MemSet16(u16* _dst,u16 _value,u32 _count);
extern "C" void MemSet8(u8* _dst,u8 _value,u32 _count);

extern "C" void sys_lock_gui();
extern "C" void sys_unlock_gui();
extern "C" CKernel* KernelInstance;
#endif