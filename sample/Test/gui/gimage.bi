
enum HorizontalAlignment
    Left = 0
    Right = 1
    Center = 2
end enum

type RGBType field = 1
    R as unsigned byte
    G as unsigned byte
    B as unsigned byte
end type

Type BMPHeader field = 1
        format  as Unsigned SHORT
        size    as unsigned long
        reserved1 as unsigned short
        reserved2 as unsigned short
        dataOffset as unsigned long
        
        dibSize as unsigned long
        pixelWidth as unsigned long
        pixelHeight as unsigned long
        colorPlanes as unsigned short
        bitsPerPixel as unsigned short
        compressionMethod as unsigned long
        ImageSize as unsigned long
        XRes as unsigned long
        YRes as unsigned long
        ColCH as unsigned long
        IC as unsigned long
end type


TYPE GImage field = 1'  extends VM_GC
    Width          as integer
    Height         as integer
    Buffer         as unsigned long ptr
    BufferSize      as unsigned integer
    declare constructor()
    declare destructor()
    
    declare sub SetSize(w as integer,h as integer)   
    declare sub CreateBuffer()
    declare sub Clear(c as unsigned long)
    declare sub SetPixel(_x as integer,_y as integer,c as unsigned long)
    declare sub DrawLine(x1 as integer,y1 as integer,x2 as integer,y2 as integer,c as unsigned long)
    declare sub FillRectangle(x1 as integer,y1 as integer,x2 as integer,y2 as integer, c as unsigned long)
    declare sub FillRectangleAlpha(x1 as integer,y1 as integer,x2 as integer,y2 as integer, c as unsigned long)
    declare sub FillRectangleAlphaHalf(x1 as integer,y1 as integer,x2 as integer,y2 as integer,c as unsigned long)
    declare sub DrawRectangle(x1 as integer,y1 as integer,x2 as integer,y2 as integer, c as unsigned long)
    declare sub PutOtherRaw(src as unsigned long ptr,_w as integer,_h as integer,x as integer,y as integer)
    declare sub PutOther(src as GImage ptr,x as integer,y as integer,transparent as integer)
    declare sub PutOtherPart(src as GImage ptr,x as integer,y as integer,sourceX as integer,sourceY as integer,sourceWidth as integer,sourceHeight as integer, transparent as integer)
    
    declare sub DrawText(txt as unsigned byte ptr,x1 as integer,y1 as integer,c as integer,fdata as FontData ptr,ratio as integer)
    declare sub DrawChar(asciicode as unsigned byte,x1 as integer,y1 as integer,c as integer,fdata as FontData ptr,ratio as integer)
	
    declare static Function LoadFromBitmap(path as unsigned byte ptr) as GImage ptr
    declare static Function LoadFromBitmapBuffer(buffer as unsigned byte ptr,fsize as unsigned integer) as GImage ptr
   
end type