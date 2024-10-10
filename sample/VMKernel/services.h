#ifndef _services_h
#define _services_h
#include <fatfs/ff.h>
#include <circle/util.h>
#include <circle/logger.h>
#include <circle/alloc.h>
#include <circle/bcmrandom.h>

extern "C" void* vfs_load_file(const TCHAR* path,u32 *fsize);
extern "C" void vfs_write_file(const TCHAR* path,void* buffer,u32 fsize);
extern "C" u32 get_random(u32 min,u32 max);
#endif