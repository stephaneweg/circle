
dim shared GUI_FocusedElement as GUI_ELEMENT ptr

constructor GUI_ELEMENT()
	this.constructor(0,0,0,0)
end constructor
#define GUI_ELEM_MAGIC &h6331
constructor GUI_ELEMENT(l as integer,t as integer,w as integer,h as integer)
	CatchMouseOutsideBounds = 0
    'MAGIC2      = GUI_ELEM_MAGIC
    VMCTX       = 0
	FirstNode	= 0
	LastNode	= 0
	PrevNode	= 0
	NextNode	= 0
	ParentNode	= 0
	IsValid		= 0
	PrevHandled	= 0
    HasFocus    = 0
	Left	= l
	Top		= t
	This.Width	= w
	Height	= h
    PaddingLeft = 0
    PaddingTop  = 0
    Transparent = 0
    ShouldRedraw        = 1
    OnGotFocusMethod    = 0
	OnLostFocusMethod   = 0
	DrawMethod          = 0
	HandleMouseMethod   = 0
	DestroyMethod       = cptr(any ptr,@GUI_ELEMENT_DESTROY)
    VisitMethod         = cptr(any ptr,@GUI_ELEMENT_VISIT)
    CanTakeAutoFocus    = 0
    
	this.CreateBuffer()
end constructor

destructor GUI_ELEMENT()
    var c = this.FIrstNode
    while c<>0
        var n = c->NextNode
        this.RemoveChild(c)
        c = n
    wend
end destructor

sub GUI_ELEMENT_DESTROY(g as GUI_ELEMENT ptr)
        g->destructor()
end sub

sub GUI_ELEMENT_VISIT(g as GUI_ELEMENT ptr)
    'g->VISITED = 1
    'var n = g->FirstNode
    'while n<>0
    '    if (n->VISITED = 0) then
    '        GUI_ELEMENT_VISIT(n)
    '    end if
    '    n = n->NextNode
    'wend
end sub

sub GUI_ELEMENT.BringToFront()
	if (this.ParentNode<>0) then
		if (this.NextNode<>0) then
			var p = this.ParentNode
			p->RemoveChild(@this)
			p->AddChild(@this)
		end if
	end if
end sub

sub GUI_ELEMENT.AddChild(child as GUI_ELEMENT ptr)
	if (child->ParentNode = 0) then
		child->ParentNode = @this
		child->PrevNode = this.LastNode
		child->NextNode = 0
		if (this.LastNode<>0) then
			this.LastNode->NextNode = child
		else
			this.FirstNode = child
		end if
		this.LastNode = child
		this.Invalidate(true)
        
	end if
end sub

sub GUI_ELEMENT.RemoveChild(child as GUI_ELEMENT ptr)
	if (child->ParentNode=@this) then
        if (GUI_FocusedElement= child) then GUI_FocusedElement = 0
		if PrevHandled = child then PrevHandled = 0
		if (child->PrevNode<>0) then 
			child->PrevNode->NextNode = child->NextNode
		else
			this.FirstNode = child->NextNode
		end if
		if (child->NextNode<>0) then 
			child->NextNode->PrevNode = child->PrevNode
		else
			this.LastNode = child->PrevNode
		end if
		child->ParentNode= 0
		this.Invalidate(true)
        
	end if
end sub

sub GUI_ELEMENT.Invalidate(_shouldRedraw as boolean)
	IsValid = 0
    if (_shouldRedraw) then ShouldRedraw = 1
	if (ParentNode<>0) then ParentNode->Invalidate(false)
end sub

function GUI_ELEMENT.HandleKeyboard(c as unsigned byte) as integer
    dim handled as integer = 0
	if (this.HasFocus=1) then
        var child = this.FirstNode
        while child<>0
            if (child->HasFocus=1) then
                handled = child->HandleKeyboard(c)
                if (handled<>0) then exit while
            end if
            child=child->NextNode
        wend
        if (handled=0) then
            if (HandleKeyboardMethod<>0) then
                handled = HandleKeyboardMethod(@this,c)
            end if
        end if
    end if
    return handled
end function
    
function GUI_ELEMENT.HandleMouse(mx as integer,my as integer,bleft as integer,bright as integer,bmiddle as integer,wheel as integer) as integer
	dim handled as integer = 0
	dim handledElement as GUI_ELEMENT ptr = 0
	
	if (handled = 0) then
		dim node as GUI_ELEMENT ptr = this.LastNode
		while node<>0 and handled=0
			dim n as GUI_ELEMENT ptr = node->PrevNode
			var isOver = (mx>=node->Left and my>=node->Top and mx<node->Left+node->Width and my<node->Top+node->Height) 
			if isOver or (node->CatchMouseOutsideBounds=1) then
				handled = node->HandleMouse(mx-node->Left,my-node->Top,bleft,bright,bmiddle,wheel)
				if (handled=1) then
					handledElement = node
				end if
			end if
			'if mouse is over this element, the element behind cannot handle he mouse now
			if isOver then exit while
			node=n
		wend
	end if
	
    if (handled=0) then
        if (HandleMouseMethod<>0) then
            handled = HandleMouseMethod(@this,mx,my,bleft,bright,bmiddle,wheel)
        end if
    end if
	if (PrevHandled<>0 and PrevHandled<>handledElement) then
		PrevHandled->HandleMouse(-1,-1,0,0,0,0)
	end if
	PrevHandled = handledElement
	
	return handled
end function

sub GUI_ELEMENT.Draw()
	if (IsValid=0) then
        if (ShouldRedraw = 1) then
            if (DrawMethod<>0) then
                DrawMethod(@this)
            end if
            ShouldRedraw = 0
		end if
		
		'todo draw the children then put them to this buffer
		dim node as GUI_ELEMENT ptr = this.FirstNode
		while node<>0
			node->Draw()
			this.PutOther(node,node->Left,node->Top,node->Transparent)
			node=node->NextNode
		wend
		IsValid = 1
	end if
end sub

sub GUI_ELEMENT.TakeFocus()
	if (GUI_FocusedElement<>@this) then
		if (GUI_FocusedElement<>0) then
			GUI_FocusedElement->LostFocusInternal()
		end if
		
		this.TakeFocusInternal()
		
		GUI_FocusedElement = @this
		if (GUI_FocusedElement->OnGotFocusMethod<>0) then
			GUI_FocusedElement->OnGotFocusMethod(GUI_FocusedElement)
		end if
	end if
end sub

sub GUI_ELEMENT.LostFocusInternal()
	this.HasFocus = 0
	if (OnLostFocusMethod<>0) then
		OnLostFocusMethod(@this)
	end if
	
    var child = this.FirstNode
    while child <>0
        child->LostFocusInternal()
        child= child->NextNode
    wend
	
	
	if (GUI_FocusedElement=@this) then GUI_FocusedElement = 0
end sub

sub GUI_ELEMENT.TakeFocusInternal()
	this.HasFocus = 1
	if (this.ParentNode<>0) then this.ParentNode->TakeFocusInternal()
end sub

sub GUI_ELEMENT.FocusNext()
	if (this.ParentNode<>0) then
        var node = this.NextNode
        if (node=0) then node = this.ParentNode->FirstNode
        
        while node<>0 and node<>@this
            if (node->CanTakeAutoFocus=1) then 
                node->TakeFocus()
                exit sub
            end if
            node =node->NextNode
            if (node=0) then node = this.ParentNode->FirstNode
      
        wend
	end if
end sub