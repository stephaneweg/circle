
#include once "stdlib.bi"
#include once "../system.bi"
static shared Result(0 to 2047) as unsigned byte
static shared Result2(0 to 2047) as unsigned byte
static shared Result3(0 to 2047) as unsigned byte


function StringHash(src as unsigned byte ptr,bytescount as integer) as unsigned longint
    dim p as  unsigned longint = 255'31
    dim m as  unsigned longint =-1' 1e9+9
    dim p_pow  as  unsigned longint = 1
    dim hash_val as unsigned longint = 0
 
    for i as integer = 0 to bytescount-1
        dim h as unsigned longint=src[i]+1' - asc("a") +1
        hash_val    = (hash_val + h * p_pow) mod m
        p_pow       = (p * p_pow  ) mod m
    next
    return hash_val
    
    'dim lcount as integer = bytescount/8
    'dim hash as unsigned longint    = bytescount
    'dim l as unsigned longint ptr   = src
    'for i as integer =0 to lcount-1
    '    hash+=l[i]
    'next
    'return hash
end function
    
function strtoupper(s as unsigned byte ptr) as unsigned byte ptr
    dim i as integer = 0
    dim d as unsigned byte ptr = @Result(0)
    dim b as unsigned byte
    while (*s)<>0
        b = *s
        if (b>=asc("a")) and (b<=asc("z")) then b = (b+asc("A")) - asc("a")
        *d = b
        s+=1
        d+=1
    wend
    *d = *s
    return @Result(0)
end function     

function strcpy(dst as unsigned byte ptr,src as unsigned byte ptr) as unsigned byte ptr
    dim i as unsigned integer
    i=0
    while src[i]<>0
        dst[i]=src[i]
        i+=1
    wend
    dst[i]=src[i]
    return dst
end function

function strcmp(s1 as unsigned byte ptr,s2 as unsigned byte ptr) as integer
    dim b as byte ptr
    dim i as integer
    i = 0
    while (*s1<>0 and *s2<>0) and (*s1)=(*s2)
        s1+=1
        s2+=1
    wend
    return s1-s2
end function

sub strrev(s as unsigned byte ptr)
    
    dim l as integer=strlen(s)
    dim i as integer
    dim tmp as unsigned byte
    dim tmp2 as unsigned byte
    for i=0 to (l/2)-1
        tmp=s[i]
        tmp2=s[l-i-1]
        s[i] = tmp2
        s[l-i-1]=tmp
    next i
end sub

function strcat(s1 as unsigned byte ptr,s2 as unsigned byte ptr) as unsigned byte ptr
    dim i1 as unsigned integer=0
    dim i2 as unsigned integer=0
    dim dst as unsigned byte ptr=@(Result(0))
    while s1[i1]<>0 and i1<1022
        dst[i1]=s1[i1]
        i1+=1
    wend
    
    while s2[i2]<>0 and i1+i2<1022
        dst[i1+i2]=s2[i2]
        i2+=1
    wend
    dst[i1+i2]=0
    return dst
end function

function strlen(s as unsigned byte ptr) as unsigned integer
    dim retval as unsigned integer
    retval=0
    while s[retval]<>0
        retval+=1
    wend
    return retval
end function

function strtrim(s as unsigned byte ptr) as unsigned byte ptr
    dim retval  as unsigned byte ptr=@(Result(0))
    retval[0]=0
    dim i as integer=0
    dim j as integer=0
    while (s[i]<>0 and s[i]=32 and s[i]<>9 and s[i]<>10 and s[i]<>13)
        i+=1
    wend
    while(s[i]<>0)
        retval[j]=s[i]
        i+=1
        j+=1
    wend
    retval[j]=0
    
    strrev(retval)
    
    i=0
    j=0
    while (retval[i]<>0 and retval[i]=32 and retval[i]=9 and retval[i]=10 and retval[i]=13)
        i+=1
    wend
    while(retval[i]<>0)
        retval[j]=retval[i]
        i+=1
        j+=1
    wend
    retval[j]=0
    strrev(retval)
    
    return retval
end function

function strtolower(s as unsigned byte ptr) as unsigned byte ptr
    dim i as unsigned integer
    dim dst as unsigned byte ptr=@(Result(0))
    i=0
    while s[i]<>0 and i<1022
        if (s[i]>=65 and s[i]<=90) then
            dst[i]=s[i]+32
        else
            dst[i]=s[i]
        end if
        i+=1
    wend
    dst[i]=0
    return dst
end function

function substring(s as unsigned byte ptr,index as unsigned integer, count as integer) as unsigned byte ptr
    dim i as unsigned integer
    dim dst as unsigned byte ptr=@(Result(0))
    dim l as unsigned integer=strlen(s)
    i=0
    while s[i+index]<>0 and i+index<1022 and i+index<l  and (i<count or count=-1)
        dst[i]=s[i+index]
        i+=1
    wend
    dst[i]=0
    return dst
end function


function strlastindexof(s as unsigned byte ptr,s2 as unsigned byte ptr) as integer
    var l1=strlen(s)
    var l2=strlen(s2)
    dim i as integer
    dim j as integer
    var ok=0
    for i=l1-l2 to 0 step -1
        if s[i]=s2[0] then
            ok=1
            for j=0 to l2-1
                if s[i+j]<>s2[j] then 
                    ok=0
                    exit for
                end if
            next j
            if ok<>0 then return i
        end if
    next i
    return -1
end function

function strindexof(s as unsigned byte ptr,s2 as unsigned byte ptr) as integer
    var l1=strlen(s)
    var l2=strlen(s2)
    dim i as integer
    dim j as integer
    var ok=0
    for i=0 to l1-l2
        if s[i]=s2[0] then
            ok=1
            for j=0 to l2-1
                if s[i+j]<>s2[j] then 
                    ok=0
                    exit for
                end if
            next j
            if ok<>0 then return i
        end if
    next i
    return -1
end function

function atoi(s as unsigned byte ptr) as integer
    if (s[0]= 48) and ((s[1]=120) or (s[1]=88)) then return atoihex(s+2)
    if (s[0]= 38) and ((s[1]=104) or (s[1]=72)) then return atoihex(s+2)
    
    dim res as integer=0
    dim i as integer=0
    dim fact as integer=1
    if (s[0]=45) then 
        fact=-1
        i=1
    end if
    if (s[0]=43) then i=1
    while (s[i]<>0)
        res=res*10+ s[i]-48
        i+=1
    wend
    return res*fact
end function


function atof(s as unsigned byte ptr) as double
    dim rez as double =0
    dim fact as double=1
    if (s[0]=45) then
        s+=1
        fact =-1
    end if
    dim point_seen as integer=0
    dim i as integer =0
    dim d as integer
    while s[i]<>0
        if (s[i] = 46) then
            point_seen = 1
        else
            d = s[i] - 48 '- "0"
            if (d >= 0 and d <= 9) then
                if (point_seen<>0) then fact =  fact /10.0
                rez = rez * 10.0 + cast(double,d)
            end if
        end if
        i+=1
    wend    
    
 
  return rez * fact
end function

function atoihex(s as unsigned byte ptr) as unsigned integer
    dim res as integer=0
    dim i as integer=0
    dim d as integer
     while (s[i]<>0)
        d=s[i]
        if (d>=48 and d<=57) then res=res*16+ d-48
        if (d>=65 and d<=70) then res=res*16+ d-55
        if (d>=97 and d<=102) then res=res*16+ d-87
        i+=1
    wend
    return res
end function

function atol(s as unsigned byte ptr) as long
    if (s[0]= 48) and ((s[1]=120) or (s[1]=88)) then return atolhex(s+2)
    
    dim res as long=0
    dim i as long=0
    dim fact as long=1
    if (s[0]=45) then 
        fact=-1
        i=1
    end if
    if (s[0]=43) then i=1
    while (s[i]<>0)
        res=res*10+ s[i]-48
        i+=1
    wend
    return res*fact
end function

function atolhex(s as unsigned byte ptr) as unsigned long
    dim res as long=0
    dim i as long=0
    dim d as long
     while (s[i]<>0)
        d=s[i]
        if (d>=48 and d<=57) then res=res*16+ d-48
        if (d>=65 and d<=70) then res=res*16+ d-55
        if (d>=97 and d<=102) then res=res*16+ d-87
        i+=1
    wend
    return res
end function


function DoubleToStr(c as double) as unsigned byte ptr
    var dbl=c
    dim neg as integer=0
    if dbl<0 then
        neg=-1
        dbl=-dbl
    end if
    
    
    dim intDbl as double =  floor(dbl)
    'var floatPart=(dbl*cast(double,10000000000))-(intDbl*10000000000)
    var floatPart=(dbl*cast(double,1000000))-(intDbl*1000000)
    if neg then
        intDbl=intDbl
    end if
    
    dim strResult as unsigned byte ptr= @(Result(0))
    strCpy(strResult,IntToStr(intDbl,10))
    
    if (floatPart>0) then
        
         strCat(strResult,@".")
         'if (floatPart<1000000000) then strCat(strResult,@"0")
         'if (floatPart<100000000) then strCat(strResult,@"0")
         'if (floatPart<10000000) then strCat(strResult,@"0")
         'if (floatPart<1000000) then strCat(strResult,@"0")
         if (floatPart<100000) then strCat(strResult,@"0")
         if (floatPart<10000) then strCat(strResult,@"0")
         if (floatPart<1000) then strCat(strResult,@"0")
         if (floatPart<100) then strCat(strResult,@"0")
         if (floatPart<10) then strCat(strResult,@"0")
         strCat(strResult,IntToStr(floatPart,10))
    end if
    if (neg) then
        var l = strlen(strResult)
        strrev(strResult)
        strResult[l]=45
        strResult[l+1]=0
        strrev(strResult)
    end if
    return strResult
end function

function IntToStr (number as longint,abase as unsigned integer) as unsigned byte ptr
    dim buffer as unsigned byte ptr
    dim dst as unsigned byte ptr=@(Result3(0))
    dim i as  longint=number
    dim l as longint=0
    dim neg as longint=0
    dim n as longint
    dim bbase as longint = abase
    if (i=0) then
        dst[0]=48
        dst[1]=0
        return dst
    end if
    
    if (i<0) then
        i=-i
        neg=-1
    end if
    
    while (i>0)
        n = i mod bbase
        if (n<10) then
            dst[l]=n+48
        else
            dst[l]=n+55
        end if
        i=(i - n)/bbase
        l+=1
    wend
    if (neg) then
        dst[l]=45
        l+=1
    end if
    dst[l]=0
    strrev(dst)
    return dst
end function

function UIntToStr (number as unsigned longint,abase as unsigned integer) as unsigned byte ptr
    dim buffer as unsigned byte ptr
    dim dst as unsigned byte ptr=@(Result3(0))
    dim i as  unsigned longint=number
    dim l as unsigned longint=0
    dim n as unsigned longint
    if (i=0) then
        dst[0]=48
        dst[1]=0
        return dst
    end if
    
    
    while (i>0)
        n = i mod abase
        if (n<10) then
            dst[l]=n+48
        else
            dst[l]=n+55
        end if
        i=(i - n)/abase
        l+=1
    wend
    dst[l]=0
    strrev(dst)
    return dst
end function


sub MemCpyARCH cdecl alias "MemCpyARCH"(_dst as any ptr,_src as any ptr,_count as unsigned long)
    
    dim asrc as any ptr = _src
    dim adst as any ptr = _dst
    dim remainder as unsigned integer = _count
    
	dim count64 as unsigned integer = remainder shr 3
	if (count64>0) and ((cuint(adst) and 7)=0) and ((cuint(asrc) and 7)=0) then
		MemCpy64(adst,asrc,count64)
		dim c as unsigned integer = (count64 shl 3)
		remainder-=c
		asrc = cptr(any ptr, cuint(asrc)+c)
		adst = cptr(any ptr, cuint(adst)+c)
	end if
    
	dim count32 as unsigned integer = remainder shr 2
	if (count32>0) and ((cuint(adst) and 3)=0) and ((cuint(asrc) and 3) = 0) then	
		MemCpy32(adst,asrc,count32)
		dim c as unsigned integer = (count32 shl 2)
		remainder-=c
		asrc = cptr(any ptr, cuint(asrc)+c)
		adst = cptr(any ptr, cuint(adst)+c)
    end if
	
	dim count16 as unsigned integer = remainder shr 1
    if (count16>0) and ((cuint(adst) and 1)=0) and ((cuint(asrc) and 1) = 0) then   
        MemCpy16(adst,asrc,count16)
		dim c as unsigned integer = (count16 shl 1)
        remainder-=c
        asrc = cptr(any ptr, cuint(asrc)+c)
        adst = cptr(any ptr, cuint(adst)+c)
    end if
	
    if (remainder>0) then
		MemCpy8(adst,asrc,remainder)
    end if
end sub


