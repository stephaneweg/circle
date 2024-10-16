Type Skin  field=1
    leftWidth as integer
    rightWidth as integer
    topHeight as integer
    bottomHeight as integer
    partCount as integer
    skinWidth as integer
    skinHeight as integer
    
    Image as GImage ptr
    
    declare static function CreateFromImage(img as GImage ptr,count as unsigned integer,lw as integer,rw as integer,th as integer, bh as integer) as Skin ptr
    declare static function CreateFromBuffer(buffer as any ptr,buffersize as unsigned integer,count as unsigned integer,lw as integer,rw as integer,th as integer, bh as integer) as Skin ptr
    declare static function Create(path as unsigned byte ptr,count as unsigned integer,lw as integer,rw as integer,th as integer, bh as integer) as Skin ptr
    declare sub DrawOn(target as GImage ptr,num as unsigned integer,x as integer,y as integer,w as integer,h as integer,transparent as integer)
    declare sub ApplyColor(c as unsigned integer,all as unsigned integer)
    declare constructor()
    declare destructor()
end type