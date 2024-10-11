declare sub kwrite cdecl alias "kwrite"(txt as unsigned byte ptr)
declare sub kwriteLine cdecl alias "kwriteLine"(txt as unsigned byte ptr)
declare sub kwriteFormat cdecl alias "kwriteFormat"(txt as unsigned byte ptr,...)
declare sub kwriteFormatLine cdecl alias "kwriteFormatLine"(txt as unsigned byte ptr,...)
declare sub knewline cdecl alias "knewline"()

declare function VFS_LOAD_FILE cdecl alias "vfs_load_file"(path as unsigned byte ptr,fsize as unsigned long ptr) as unsigned byte ptr
declare sub VFS_WRITE_FILE cdecl alias "vfs_write_file"(path as unsigned byte ptr,buffer as unsigned byte ptr,fsize as unsigned long)
declare function get_random cdecl alias "get_random" (min as unsigned long,max as unsigned long) as unsigned long