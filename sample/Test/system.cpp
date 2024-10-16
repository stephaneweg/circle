#include "kernel.h"
#include <circle/string.h>
#include <circle/types.h>
#include "system.h"
#include <circle/bcmrandom.h>

#include <circle/alloc.h>

extern "C" void kwrite(const char* txt)
{
	KernelInstance->k_write(txt);
}

extern "C" void knewline()
{
	KernelInstance->k_write("\n");
}

extern "C" void kwriteLine(const char* txt)
{
	KernelInstance->k_writeLine(txt);
}



extern "C" void kwriteFormat(const char* txt,...)
{	
	va_list var;
	va_start (var, txt);

	kwriteFormatV (txt, var);

	va_end (var);
}

extern "C" void kwriteFormatLine(const char* txt,...)
{	
	va_list var;
	va_start (var, txt);

	kwriteFormatVLine (txt, var);

	va_end (var);
}


extern "C" void kwriteFormatV(const char* txt,va_list args)
{
	KernelInstance->k_writeFormatV(txt,args);
}

extern "C" void kwriteFormatVLine(const char* txt,va_list args)
{
	KernelInstance->k_writeFormatVLine(txt,args);
}

static const char FromServices[] = "Services";

extern "C" void vfs_write_file(const TCHAR* path,void* buffer,u32 fsize)
{
	UINT byteWritten;
	FIL File;
	FRESULT	Result = f_open (&File, path, FA_WRITE | FA_CREATE_ALWAYS);
	if (Result != FR_OK)
	{
		CLogger::Get()->Write (FromServices, LogNotice, "Cannot open file in write mode : %s", path);
		return;
	}
	
	f_write (&File, buffer, fsize, &byteWritten);
	if (byteWritten!=fsize)
	{
		CLogger::Get()->Write (FromServices, LogNotice, "only %d of %d bytes written to : %s",byteWritten,fsize, path);
	}
	
	if (f_close (&File) != FR_OK)
	{
		CLogger::Get()->Write (FromServices, LogNotice, "Cannot close file : %s",path);
	}
}

extern "C" void* vfs_load_file(const TCHAR* path,u32 *fsize)
{
	*fsize=0;
	char* buff=0;
	
	FILINFO info;
	FIL File;
	
	FRESULT result = f_stat(path,&info);
	if (result!=FR_OK)
	{
		CLogger::Get()->Write (FromServices, LogNotice, "Cannot get info of file: %s", path);
		return 0;
	}
	
	FRESULT	Result = f_open (&File, path, FA_READ);
	if (Result != FR_OK)
	{
		CLogger::Get()->Write (FromServices, LogNotice, "Cannot open file : %s", path);
		return 0;
	}
		
	*fsize = info.fsize;
	u32 nbyteread=0;
	buff = (char*)malloc(info.fsize);
	f_read(&File,buff,info.fsize,&nbyteread);
	if (Result != FR_OK)
	{
		free(buff);
		buff = 0;
		CLogger::Get()->Write (FromServices, LogNotice, "Cannot read file: %s", path);
	}
	f_close(&File);
	
	
	return buff;
}

extern "C" u32 get_random(u32 min,u32 max)
{
	u32 diff = max-min;
	CBcmRandomNumberGenerator _random;
	
	return (_random.GetNumber() % diff) + min;
}

extern "C" void sys_lock_gui()
{
	//KernelInstance->LockGui();
}

extern "C" void sys_unlock_gui()
{
	//KernelInstance->UnlockGui();
}

extern "C" s32 get_joypad_axis(u32 gamepad,u32 axis)
{
	return KernelInstance->get_joypad_axis(gamepad,axis);
}

extern "C" u32 get_joypad_buttons(u32 gamepad)
{
	return KernelInstance->get_joypad_buttons(gamepad);
}



extern "C" void MemSet64(u64* _dst,u64 _value,u32 _count)
{
	for(;_count>0;_count--,_dst++)
	{
		*_dst = _value;
	}
}

extern "C" void MemSet32(u32* _dst,u32 _value,u32 _count)
{
	for(;_count>0;_count--,_dst++)
	{
		*_dst = _value;
	}
}

extern "C" void MemSet16(u16* _dst,u16 _value,u32 _count)
{
	for(;_count>0;_count--,_dst++)
	{
		*_dst = _value;
	}
}

extern "C" void MemSet8(u8* _dst,u8 _value,u32 _count)
{
	for(;_count>0;_count--,_dst++)
	{
		*_dst = _value;
	}
}



extern "C" void MemCpy64(u64* _dst, u64* _src, u32 _count)
{
	for (;_count>0;_count--,_dst++,_src++)
	{
		*_dst = *_src;
	}
}

extern "C" void MemCpy32(u32* _dst, u32* _src, u32 _count)
{
	for (;_count>0;_count--,_dst++,_src++)
	{
		*_dst = *_src;
	}
}


extern "C" void MemCpy16(u16* _dst, u16* _src, u32 _count)
{
	for (;_count>0;_count--,_dst++,_src++)
	{
		*_dst = *_src;
	}
}

extern "C" void MemCpy8(u8* _dst, u8* _src, u32 _count)
{
	for (;_count>0;_count--,_dst++,_src++)
	{
		*_dst = *_src;
	}
}