
dim shared FontPath as unsigned byte ptr = @"SD:/FONTS/"
function LoadFont(fontname as unsigned byte ptr) as FontData ptr
	
    dim buffer as unsigned byte ptr
    dim fsize as unsigned long=0
    buffer=vfs_load_file(strCat(strcat(FontPath,fontname),@".fon"),@fsize)
    if (buffer=0 or fsize=0) then
        return 0
    end if
    dim result  as FontData ptr = CPTR(FontData ptr, allocate(sizeof(FontData)))
    result->Buffer = buffer
    result->FLen = fsize
    result->FontHeight = fsize/256
    return result
end function