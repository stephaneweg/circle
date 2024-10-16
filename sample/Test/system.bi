declare sub kwrite cdecl alias "kwrite"(txt as unsigned byte ptr)
declare sub kwriteLine cdecl alias "kwriteLine"(txt as unsigned byte ptr)
declare sub kwriteFormat cdecl alias "kwriteFormat"(txt as unsigned byte ptr,...)
declare sub kwriteFormatLine cdecl alias "kwriteFormatLine"(txt as unsigned byte ptr,...)
declare sub knewline cdecl alias "knewline"()

declare function VFS_LOAD_FILE cdecl alias "vfs_load_file"(path as unsigned byte ptr,fsize as unsigned long ptr) as unsigned byte ptr
declare sub VFS_WRITE_FILE cdecl alias "vfs_write_file"(path as unsigned byte ptr,buffer as unsigned byte ptr,fsize as unsigned long)
declare function get_random cdecl alias "get_random" (min as unsigned long,max as unsigned long) as unsigned long

declare sub sys_lock_gui cdecl alias "sys_lock_gui"()
declare sub sys_unlock_gui cdecl alias "sys_unlock_gui"()

declare function get_joypad_axis cdecl alias "get_joypad_axis"(gamepad as long,axis as long) as long
declare function get_joypad_buttons cdecl alias "get_joypad_buttons"(gamepad as long) as unsigned long

declare sub MemCpy64 cdecl alias "MemCpy64"(_dst as unsigned longint ptr,_src as unsigned longint ptr,_count as unsigned long)
declare sub MemCpy32 cdecl alias "MemCpy32"(_dst as unsigned long ptr,_src as unsigned long ptr,_count as unsigned long)
declare sub MemCpy16 cdecl alias "MemCpy16"(_dst as unsigned short ptr,_src as unsigned short ptr,_count as unsigned long)
declare sub MemCpy8 cdecl alias "MemCpy8"(_dst as unsigned byte ptr,_src as unsigned byte ptr,_count as unsigned long)


declare sub MemSet64 cdecl alias "MemSet64"(_dst as unsigned longint ptr,_value as unsigned longint,_count as unsigned long)
declare sub MemSet32 cdecl alias "MemSet32"(_dst as unsigned long ptr,_value as unsigned long,_count as unsigned long)
declare sub MemSet16 cdecl alias "MemSet16"(_dst as unsigned short ptr,_value as unsigned short,_count as unsigned long)
declare sub MemSet8 cdecl alias "MemSet8"(_dst as unsigned byte ptr,_value as unsigned byte,_count as unsigned long)