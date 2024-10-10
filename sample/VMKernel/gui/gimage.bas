
constructor GImage()
    this.Width  = 0
    this.Height = 0
    this.Buffer = 0
    this.BufferSize = 0
end constructor

destructor GImage()
    this.Width  = 0
    this.Height = 0
    this.Buffer = 0
end destructor


sub GImage.SetSize(w as integer,h as integer)
    if (w<>this.Width or h<>this.Height) then
        this.Width     = w
        this.Height    = h
        this.CreateBuffer()
    end if
end sub

sub GImage.CreateBuffer()
    dim newsize as unsigned integer = this.Width*this.Height*sizeof(unsigned long)
    if (newsize>this.BufferSize) then
        if (this.Buffer<>0) then
			deallocate this.Buffer
			this.Buffer = 0
            this.BufferSize = 0
		end if
        
       'dim pagesCount	as unsigned integer =  ((newsize + 4095) and -4096) shr 12
       'newsize = pagesCount shl 12
       this.Buffer = allocate(newSize)
       this.BufferSize = newSize
    end if
    
end sub

sub GImage.Clear(c as unsigned long)
	if (this.Buffer=0) then exit sub
	this.FillRectangle(0,0,this.Width-1,this.Height-1,c)
end sub

sub GImage.SetPixel(_x as integer,_y as integer,c as unsigned long)
	if (this.Buffer=0) then exit sub
    if (_x>=0 and _y>=0 and _x<this.Width and _y<this.Height) then
        this.Buffer[_y*this.Width+_x] = c
    end if
end sub

sub GImage.DrawLine(x1 as integer,y1 as integer,x2 as integer,y2 as integer,c as unsigned long)
    if (this.Buffer=0) then exit sub
        dim x as integer
        dim y as integer
        
        dim fx as integer
        dim fy as integer
        dim lx as integer
        dim ly as integer
        dim addr as unsigned integer
        dim bpl as unsigned integer=this.Width*4
        dim cpt as unsigned integer
        fx=x1:	lx=x2:	fy=y1:	ly=y2
        
        'vertical line
        if (fx=lx) then
            if (fy>ly) then fy=y2: ly=y1
            if (fy<0) then fy=0
            if (ly>=this.Height) then ly = this.Height-1
            addr = cast(unsigned integer,this.Buffer) + ((fy*this.Width+fx)*4)
            cpt = (ly-fy)+1
			
			for _yy as integer = fy to ly
				SetPixel(fx,_yy,c)
			next
            exit sub
        end if
        
        'horizontal line
        if (fy=ly) then
            if (fy>=0 and fy<this.Height) then
                if (fx>lx) then fx=x2: lx=x1                
                if (fx<0) then fx=0
                if (lx>=this.Width) then lx=this.Width-1
                addr = cast(unsigned integer,this.Buffer) + ((fy*this.Width+fx)*4)
                cpt = (lx-fx)+1
				for _xx as integer = fx to lx
					SetPixel(_xx,fy,c)
				next
            end if
            exit sub
        end if
    
        'oblique line
        dim dx as integer=0
        dim sx as integer
        if (x1>x2) then dx=x1-x2
        if (x2>x1) then dx=x2-x1
        if x1<x2 then 
            sx=1
        else
            sx=-1
        end if
        
        dim dy as integer=0
        dim sy as integer
        if (y1>y2) then dy=y1-y2
        if (y2>y1) then dy=y2-y1
        if y1<y2 then 
            sy=1
        else
            sy=-1
        end if
        
        dim aerr as integer
        if (dx>dy) then
            aerr=dx
        else
            aerr=-dy
        end if
        aerr=aerr\2
        dim e2 as integer
        do
            if (x1>=0 and y1>=0 and x1<this.Width and y1<this.Height) then
				SetPixel(x1,y1,c)
            end if
           
            
            if (x1=x2 and y1=y2) then exit do
            e2=aerr
            if (e2>-dx) then
                aerr=aerr-dy
                x1=x1+sx
            end if
            if (e2<dy) then
                aerr=aerr+dx
                y1=y1+sy
            end if
        loop
        
end sub

sub GImage.DrawRectangle(x1 as integer,y1 as integer,x2 as integer,y2 as integer, c as unsigned long)
	if (this.Buffer=0) then exit sub

   DrawLine(x1,y1,x2,y1,c)
   DrawLine(x1,y1,x1,y2,c)
   DrawLine(x2,y1,x2,y2,c)
   DrawLine(x1,y2,x2,y2,c)
end sub

sub GImage.FillRectangleAlphaHalf(x1 as integer,y1 as integer,x2 as integer,y2 as integer,c as unsigned long)
     if (this.Buffer=0) then exit sub
	 
        dim r as unsigned integer = (c and &hFF0000) shr 16
        dim g as unsigned integer = (c and &h00FF00) shr 8
        dim b as unsigned integer = (c and &h0000FF)
        for _y as integer=y1 to y2
            
            for _x as integer = x1 to x2
                if _x>=0 and _x<this.Width and _y>=0 and _y<this.Height then
                    
                    dim o as unsigned integer = _y * this.Width + _x
                    if ((this.Buffer[o] and &hFFFFFF) <> &hFF00FF ) then
                        dim l as unsigned integer= this.Buffer[o] and &h000000FF
                        dim rr as unsigned integer = ((r*l) \ 255) and &hFF  
                        dim gg as unsigned integer = ((g*l) \ 255) and &hFF
                        dim bb as unsigned integer = ((b*l)\255) and &hFF
                        this.Buffer[o] = (this.Buffer[o] and &hFF000000) or (rr shl 16) or (gg shl 8) or (bb)
                    end if
                end if
            next
        next
end sub


sub GImage.FillRectangle(x1 as integer,y1 as integer,x2 as integer,y2 as integer, c as unsigned long)
	if (this.Buffer=0) then exit sub
    dim sx1 as integer
    dim sy1 as integer
    dim sw as integer
    dim sh as integer
    dim dx as integer
    dim dy as integer
    
    'if (x1>=this.Width or y1>=this.Height or x2<0 or y2<0) then exit sub
    
    dx = x1
    dy = y1
    sw = (x2-x1)+1
    sh = (y2-y1)+1
    
    sx1 = 0
    sy1 = 0
    
    if (x1<0) then
        sx1 = -x1
        dx = 0
        sw = sw+x1
    end if
    
    if (y1<0) then 
        sy1 = -y1
        dy = 0
        sh = sh+y1
    end if
    
    if (dx + sw>= this.Width) then
        sw = this.Width-dx
    end if
    if (dy + sh>=this.Height) then
        sh = this.Height-dy
    end if
    
    dim doffset as integer
    doffset = dy * this.Width + dx
    sh -=1
    sw -=1
    dim nx as integer
    dim ny as integer
    dim dstwidth as unsigned integer=this.Width
    dim addr as unsigned integer = cast(unsigned integer,this.Buffer)+doffset*4
    dim bpl as unsigned integer = this.Width*4
    sh+=1
    sw+=1
	
	for _yy as unsigned integer = 1 to sh
		var addr2 = cptr(unsigned long ptr, addr)
		for _xx as unsigned integer = 0 to sw-1
			addr2[_xx]=c
		next
		addr+=bpl
	next 
	
  
end sub

sub GImage.PutOtherRaw(src as unsigned long ptr,_w as integer,_h as integer,x as integer,y as integer)
	if (this.Buffer=0) then exit sub
	if (src=0) then exit sub
	if (_w<=0) then exit sub
	if (_h<=0) then exit sub

    dim sx1 as integer
    dim sy1 as integer
    dim sw as integer
    dim sh as integer
    dim dx as integer
    dim dy as integer
    
    dim thiswidth as integer = cast(integer,this.Width)
    dim thisheight as integer = cast(integer,this.Height)
    
    dx = x
    dy = y
    sw = _w
    sh = _h
    
    if (x>=thiswidth or y>=thisheight or x+sw<=0 or y+sh<=0) then exit sub
    
    sx1 = 0
    sy1 = 0
    
    if (x<0) then
        sx1 = -x
        dx = 0
        sw = sw+x
    end if
    
    if (y<0) then 
        sy1 = -y
        dy = 0
        sh = sh+y
    end if
    
    if (dx + sw>= this.Width) then
        sw = thiswidth-dx
    end if
    if (dy + sh>=this.Height) then
        sh = thisheight-dy
    end if
    
    dim soffset as integer 
    dim doffset as integer
    soffset = sy1 * _w + sx1
    doffset = dy * this.Width + dx
    sh -=1
    sw -=1
    dim nx as integer
    dim ny as integer
    
    dim srcwidth as unsigned integer=_w*4
    dim dstwidth as unsigned integer=this.Width*4
    
    dim srcAddr as unsigned integer =  cast(unsigned integer,src)+(soffset*4)
    dim dstAddr as unsigned integer = cast(unsigned integer,this.Buffer)+(doffset*4)
    sh+=1
    sw+=1
  
	for _yy as integer = 1 to sh
		var addrS = cptr(unsigned long ptr,srcAddr)
		var addrD = cptr(unsigned long ptr,dstAddr)
		'for _xx as integer =0 to sw-1
		'	addrD[_xx]=addrS[_xx]
		'next		
		memcpyarch(addrD,addrS,sw shl 2)
		srcAddr+=srcWidth
		dstAddr+=dstWidth
    next
end sub

sub GImage.PutOther(src as GImage ptr,x as integer,y as integer,transparent as integer)
	if (this.Buffer=0) then exit sub
	if (src=0) then exit sub
	if (src->Buffer=0) then exit sub
	if (src->Width=0) then exit sub
	if (src->Height=0) then exit sub

    dim sx1 as integer
    dim sy1 as integer
    dim sw as integer
    dim sh as integer
    dim dx as integer
    dim dy as integer
	if (src=0) then exit sub
	if (src->Buffer=0) then exit sub
    dim thiswidth as integer = cast(integer,this.Width)
    dim thisheight as integer = cast(integer,this.Height)
    
    dx = x
    dy = y
    sw = src->Width
    sh = src->Height
    
    if (x>=thiswidth or y>=thisheight or x+sw<=0 or y+sh<=0) then exit sub
    
    sx1 = 0
    sy1 = 0
    
    if (x<0) then
        sx1 = -x
        dx = 0
        sw = sw+x
    end if
    
    if (y<0) then 
        sy1 = -y
        dy = 0
        sh = sh+y
    end if
    
    if (dx + sw>= this.Width) then
        sw = thiswidth-dx
    end if
    if (dy + sh>=this.Height) then
        sh = thisheight-dy
    end if
    
    dim soffset as integer 
    dim doffset as integer
    soffset = sy1 * src->Width + sx1
    doffset = dy * this.Width + dx
    
    dim nx as integer
    dim ny as integer
    
    dim srcwidth as unsigned integer=src->Width*4
    dim dstwidth as unsigned integer=this.Width*4
    
    dim srcAddr as unsigned integer = cast(unsigned integer,src->Buffer)+(soffset*4)
    dim dstAddr as unsigned integer = cast(unsigned integer,this.Buffer)+(doffset*4)
  
	
    if (transparent) then
        sh-=1
        sw-=1
        for ny = 0 to sh
            for nx = 0 to sw
                var c = src->Buffer[soffset+nx] and &hFFFFFF
                if (c<>&hFF00FF) then
                    this.Buffer[doffset + nx] = c or &hFF000000
                end if
            next
            soffset+=src->Width
            doffset+=this.Width
        next 
    else
        
        for _yy as integer = 1 to sh
            var addrS = cptr(unsigned long ptr,srcAddr)
            var addrD = cptr(unsigned long ptr,dstAddr)
            'for _xx as integer =0 to sw-1
            '	addrD[_xx]=addrS[_xx]
            'next
            memcpyarch(addrD,addrS,sw shl 2)
            srcAddr+=srcWidth
            dstAddr+=dstWidth
        next
     '   for ny = 0 to sh
     '       BufferToBuffer(this.Buffer+(doffset*4),src->Buffer+(soffset*4),sw+1,4,4)
            'for nx = 0 to sw
            '    this.Buffer[doffset + nx] = src->Buffer[soffset+nx]
            'next
     '       soffset+=src->Width
     '       doffset+=this.Width
     '   next 
    end if
end sub



sub GImage.PutOtherPart(src as GImage ptr,x as integer,y as integer,sourceX as integer,sourceY as integer,sourceWidth as integer,sourceHeight as integer, transparent as integer)
	if (this.Buffer=0) then exit sub
	if (src=0) then exit sub
	if (src->Buffer=0) then exit sub
	if (src->Width=0) then exit sub
	if (src->Height=0) then exit sub
	
    dim sx1 as integer
    dim sy1 as integer
    dim sw as integer
    dim sh as integer
    dim dx as integer
    dim dy as integer
    
    dim thiswidth as integer = cast(integer,this.Width)
    dim thisheight as integer = cast(integer,this.Height)
    
    dx = x
    dy = y
    sw = sourceWidth
    sh = sourceHeight
 
    sx1 = sourceX
    sy1 = sourceY
    
    if (sx1+sw)>src->Width     then sw = src->Width-sx1
    if (sy1+sh)>src->Height    then sh = src->Height-sy1
    
    if (x>=thiswidth or y>=thisheight or x+sw<=0 or y+sh<=0) then exit sub
    
    
    if (x<0) then
        sx1 = sx1-x
        dx = 0
        sw = sw+x
    end if
    
    if (y<0) then 
        sy1 = sy1-y
        dy = 0
        sh = sh+y
    end if
    
    if (dx + sw >= this.Width) then
        sw = thiswidth-dx
    end if
    if (dy + sh>=this.Height) then
        sh = thisheight-dy
    end if
    
    dim soffset as integer 
    dim doffset as integer
    soffset = sy1 * src->Width + sx1
    doffset = dy * this.Width + dx
    sh -=1
    sw -=1
    dim nx as integer
    dim ny as integer
    
    dim srcwidth as unsigned integer=src->Width*4
    dim dstwidth as unsigned integer=this.Width*4
    
    dim srcAddr as unsigned integer =  cast(unsigned integer,src->Buffer)+(soffset*4)
    dim dstAddr as unsigned integer = cast(unsigned integer,this.Buffer)+(doffset*4)
    sh+=1
    sw+=1
    
	
	for _yy as integer = 1 to sh
		var addrS = cptr(unsigned long ptr,srcAddr)
		var addrD = cptr(unsigned long ptr,dstAddr)
		'for _xx as integer =0 to sw-1
		'	addrD[_xx]=addrS[_xx]
		'next
		memcpyarch(addrD,addrS,sw shl 2)
		srcAddr+=srcWidth
		dstAddr+=dstWidth
    next
end sub


sub GImage.DrawChar(asciicode as unsigned byte,x1 as integer,y1 as integer,c as integer,fdata as FontData ptr,ratio as integer)
    if (fdata=0) then exit sub
    if (c=0) then exit sub
    
    dim fontHeight as integer=fdata->FLEN/256  
    dim fontWidth as integer=8
        
    dim rowNum as integer
    dim colNum as integer
    dim bData as unsigned byte
    
    dim x as integer
    dim y as integer
    

    for rowNum=0 to fontHeight-1
        bdata=fdata->Buffer[asciicode * fontHeight + rowNum+1]
        for colNum=0 to fontWidth -1
            if ((bData shr colNum) and &h1)=&h1 then
                    
                    if (ratio=1) then
                        x=x1+((fontWidth -1)-colNum)
                        y=rowNum+y1
                        this.SetPixel(x,y,c)
                    else
                        x=x1+((fontWidth )+((fontWidth -1)-colNum))*ratio
                        y=rowNum*ratio+y1
                        this.FillRectangle(x,y,x+ratio-1,y+ratio-1,c)
                    end if
            end if
        next
    next
end sub

sub GImage.DrawText(txt as unsigned byte ptr,x1 as integer,y1 as integer,c as integer,fdata as FontData ptr,ratio as integer)
    if (fdata=0) then exit sub
    if (txt=0) then exit sub
    dim tlen as integer
    tlen=strlen(txt)
    if tlen>0 then
        tlen=tlen-1
        
        
        dim fontHeight as integer=fdata->FLEN/256  
        dim fontWidth as integer=8
            
            
            
        dim cpt as integer
        dim rowNum as integer
        dim colNum as integer
        dim bData as unsigned byte
        dim asciicode as integer
        
        dim x as integer
        dim y as integer
        

        for cpt=0 to tlen
            asciicode=txt[cpt]
            for rowNum=0 to fontHeight-1
                bdata=fdata->Buffer[asciicode * fontHeight + rowNum+1]
                for colNum=0 to fontWidth -1
                    if ((bData shr colNum) and &h1)=&h1 then
                            
                            if (ratio=1) then
                                x=x1+(cpt*(fontWidth+1) )+((fontWidth -1)-colNum)
                                y=rowNum+y1
                                this.SetPixel(x,y,c)
                            else
                                x=x1+((cpt*fontWidth )+((fontWidth -1)-colNum))*ratio+cpt
                                y=rowNum*ratio+y1
                                this.FillRectangle(x,y,x+ratio-1,y+ratio-1,c)
                            end if
                    end if
                next
            next
        next
    end if
end sub



Function GImage.LoadFromBitmapBuffer(buffer as unsigned byte ptr,fsize as unsigned integer) as GImage ptr
    dim header as BMPHeader ptr = cptr(BMPHeader ptr,buffer)
    if (header<>0 and fsize<>0) then
        dim buff as RGBType ptr = cptr(RGBType ptr,cuint(header)+header->dataOffset)
        dim buff32 as unsigned long ptr = cptr(unsigned long ptr,cuint(header)+header->dataOffset)
        dim result as GImage Ptr = cptr(GImage ptr,allocate(sizeof(GImage)))
        result->Constructor()
        result->SetSize(header->PixelWidth,header->PixelHeight)
        
        dim i as unsigned integer
        dim c as unsigned integer
        
        dim tx as integer
        dim ty as integer
        i = 0
        for ty = header->PixelHeight-1 to 0 step -1
            for tx = 0 to header->PixelWidth-1
                if (header->bitsPerPixel=24) then
                    c = cptr(unsigned long ptr,@buff[i])[0]
                elseif(header->bitsPerPixel=32) then
                    c = buff32[i]
                end if
                'if (c and &hFFFFFF) = &hFF00FF then 
                '    c = &h0
                'else
                    c = c or &hFF000000
                'end if
                result->Buffer[(ty*header->PixelWidth)+tx] =  c
                i+=1
            next tx
        next ty
        
    
        return result
    end if
	
	return 0
end function

Function GImage.LoadFromBitmap(path as unsigned byte ptr) as GImage ptr
    dim fsize as long
    dim buffer as unsigned byte ptr = VFS_LOAD_FILE(path,@fsize)
    if (buffer<>0 and fsize<>0) then
        var result = GImage.LoadFromBitmapBuffer(buffer,fsize)
        deallocate buffer
        return result
    end if
	return 0
end function
