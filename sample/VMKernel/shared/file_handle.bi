type FILE_HANDLE extends VM_GC field = 8
    BUFFER      as unsigned byte ptr
    BUFFERSIZE  as integer
    FILESIZE    as integer
    POSITION    as integer
    PATH        as unsigned byte ptr
    
    declare constructor()
    declare destructor()
    
    declare sub REDIMBUFFER(newsize as integer)
    declare sub WriteLine(src as unsigned byte ptr)
    declare function ReadLine() as unsigned byte ptr
    declare sub Flush()
    declare sub Save()
    declare static function OpenFile(path as unsigned byte ptr) as FILE_HANDLE ptr
end type

declare sub DESTROY_FILE_HANDLE(h as FILE_HANDLE ptr)

#define VM_FILE_MAGIC        &h6873