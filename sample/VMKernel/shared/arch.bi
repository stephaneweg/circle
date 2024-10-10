declare function VFS_LOAD_FILE cdecl alias "vfs_load_file"(path as unsigned byte ptr,fsize as unsigned long ptr) as unsigned byte ptr
declare sub VFS_WRITE_FILE cdecl alias "vfs_write_file"(path as unsigned byte ptr,buffer as unsigned byte ptr,fsize as unsigned long)
declare function get_random cdecl alias "get_random" (min as unsigned long,max as unsigned long) as unsigned long
declare sub ARCH_SPINLOCK(p as integer ptr)
declare sub ARCH_UNLOCK(p as integer ptr)

