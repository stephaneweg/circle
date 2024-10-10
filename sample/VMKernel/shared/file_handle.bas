#include once "file_handle.bi"

constructor FILE_HANDLE()
    BUFFER      = 0
    BUFFERSIZE  = 0
    POSITION    = 0
    PATH        = 0
    MAGIC2      = VM_FILE_MAGIC
    DestroyMethod   = cptr(any ptr,@DESTROY_FILE_HANDLE)
    

end constructor

destructor FILE_HANDLE()
    if (BUFFER<>0) then 
        deallocate BUFFER
    end if
    BUFFER = 0
    if (PATH<>0) then 
        deallocate PATH
    end if
    PATH = 0
    POSITION    = 0
    BUFFERSIZE  = 0
    MAGIC2      = 0
end destructor

sub DESTROY_FILE_HANDLE(h as FILE_HANDLE ptr)
    h->destructor()
end sub

function FILE_HANDLE.OpenFile(path as unsigned byte ptr) as FILE_HANDLE ptr
    dim buff as unsigned byte ptr
    dim fsize as unsigned long
    buff = VFS_LOAD_FILE(strcat(@"SD:/",path),@fsize)
    dim result as FILE_HANDLE ptr = new FILE_HANDLE()
    if (fsize>0) then
        result->BUFFER      = buff
        result->FileSize    = fsize
        result->BufferSize  = fsize
    end if
    result->POSITION    = 0
    var pathLen = strlen(path)
    result->PATH        = allocate(pathLen+1)
    MemCpy8(result->PATH,path,pathLen)
    result->PATH[pathLen]=0
    return result
end function

sub FILE_HANDLE.REDIMBUFFER(newsize as integer)
    dim blocks as integer = newsize shr 9
    if (blocks shl 9)<newsize then blocks+=1
    dim size as integer = blocks shl 9
    if (size>BUFFERSIZE) then
        dim newBuffer as unsigned byte ptr = allocate(size)
        if (BUFFER<>0) then
            MemCpy8(newbuffer,buffer,BUFFERSIZE)
            deallocate BUFFER
        end if
        BUFFERSIZE = size
        BUFFER = newBuffer
    end if
end sub

sub FILE_HANDLE.Flush()
    this.FileSize = 0
    this.Position = 0
end sub

sub FILE_HANDLE.Save()
    VFS_WRITE_FILE(this.PATH,this.Buffer,this.FileSize)
end sub


sub FILE_HANDLE.WriteLine(src as unsigned byte ptr)
    var l = strlen(src)
    var newpos = this.POSITION+l+1
    REDIMBUFFER(newpos)
    if (l>0) then
        MemCpy8(cptr(unsigned byte ptr,cuint(this.buffer)+this.POSITION),src,l)
    end if
    buffer[this.POSITION+l]=10
    this.POSITION = newpos
    if (FILESIZE < this.POSITION) then FILESIZE = this.POSITION
end sub



function FILE_HANDLE.ReadLine() as unsigned byte ptr
    if (this.POSITION>=this.FILESIZE) then return 0
    dim result as unsigned byte ptr = 0
   
    for i as integer = this.POSITION to this.FILESIZE-1
        var b = this.BUFFER[i]
        
        if (b=10) then
            var slen = i-this.POSITION
            if (slen>0) then
                result = allocate(slen+1)
                
                for j as integer = this.POSITION to i
                    result[j-this.POSITION] = this.Buffer[j]
                next
                if (result[slen-1]=13) then result[slen-1]=0
                result[slen]=0
            
                this.Position = i+1
                
                kwrite(@"readline result : ")
                kwriteline(result)
                return result
            end if
        end if
    next
    dim l as integer = (this.FILESIZE-this.POSITION)+1
    result = allocate(l+1)
    
    for j as integer = this.POSITION to this.FileSize-1
        result[j-this.POSITION] = this.Buffer[j]
    next
    
    result[l]=0
    this.Position=this.FILESIZE
    return result
end function
    
    
    
    