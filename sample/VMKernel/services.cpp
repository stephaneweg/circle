
#include "services.h"
#include "system.h"

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