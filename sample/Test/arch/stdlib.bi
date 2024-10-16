declare sub strrev(s as unsigned byte ptr)

declare function IntToStr (number as longint,abase as unsigned integer) as unsigned byte ptr
declare function UIntToStr (number as unsigned longint,abase as unsigned integer) as unsigned byte ptr
declare function DoubleToStr(c as double) as unsigned byte ptr
declare function strlen(s as unsigned byte ptr) as unsigned integer
declare function strcat(s1 as unsigned byte ptr,s2 as unsigned byte ptr) as unsigned byte ptr
declare function strcpy(dst as unsigned byte ptr,src as unsigned byte ptr) as unsigned byte ptr
declare function strcmp(s1 as unsigned byte ptr,s2 as unsigned byte ptr) as integer
declare function strtoupper(s as unsigned byte ptr) as unsigned byte ptr
declare function StringHash(src as unsigned byte ptr,bytescount as integer) as unsigned longint
declare function strtrim(s as  unsigned byte ptr) as unsigned byte ptr

declare function strtolower(s as  unsigned byte ptr) as unsigned byte ptr
declare function substring(s as  unsigned byte ptr,index as unsigned integer, count as integer) as unsigned byte ptr
declare function strindexof(s as  unsigned byte ptr,s2 as  unsigned byte ptr) as integer
declare function strlastindexof(s as unsigned byte ptr,s2 as unsigned byte ptr) as integer

declare function atoi(s as unsigned byte ptr) as integer
declare function atoihex(s as unsigned byte ptr) as unsigned integer
declare function atol(s as unsigned byte ptr) as long
declare function atolhex(s as unsigned byte ptr) as unsigned long
declare function atof(s as unsigned byte ptr) as double

declare sub MemCpyAArch64  cdecl alias "MemCpyAArch64"(_dst as any ptr,_src as any ptr,_count as unsigned long)
declare sub MemCpyARCH cdecl alias "MemCpyARCH"(_dst as any ptr,_src as any ptr,_count as unsigned long)

    


#Define floor(x) (((x)*2.0-0.5)shr 1)
#define ceil(x) (-((-(x)*2.0-0.5)shr 1))
