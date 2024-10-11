#ifndef _system_h
#define _system_h

extern "C" void knewline();
extern "C" void kwrite(const char* txt);
extern "C" void kwriteLine(const char* txt);
extern "C" void kwriteFormat(const char* txt,...);
extern "C" void kwriteFormatLine(const char* txt,...);
extern "C" void kwriteFormatV(const char* txt,va_list Args);

extern "C" void* vfs_load_file(const TCHAR* path,u32 *fsize);
extern "C" void vfs_write_file(const TCHAR* path,void* buffer,u32 fsize);
extern "C" u32 get_random(u32 min,u32 max);

extern "C" CKernel* KernelInstance;
#endif