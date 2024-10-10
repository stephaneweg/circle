#include once "vm_boxedvalue.bi"
#include once "vm_string.bi"


sub VM_BoxedValue.Visit()
     if (this.vType = VM_ValueType.VMString or _
        this.vType = VM_ValueType.VMObj or _ 
        this.vType = VM_ValueType.VMTable or _
        this.vType = VM_ValueType.vmGC) then
        var gc = cptr(VM_GC ptr,cuint(this.vValue))
        if (gc->MAGIC = GC_MAGIC) then
            gc->Visit()
        end if
    end if
end sub


sub VM_BoxedValue.PrintValue()
    select case this.vTYPE
    case VM_ValueType.vmNULL:
        KWrite(@"NULL")
    case VM_ValueType.vmINT:
        KWrite(IntToStr(GetInteger(),10))
    case VM_ValueType.vmReal:
		KWrite(DoubleToStr(GetReal()))
    case VM_ValueType.vmString:
        var vs = cptr(VM_STRING ptr,cuint(vValue))
		KWrite(vs->BUFFER)
    end select
end sub
        
sub VM_BoxedValue.SetBoxed(b as VM_BoxedValue ptr)
    if (b=0) then 
        SetNull()
    else
        vType = b->vType
        vValue = b->vValue
    end if
end sub

sub VM_BoxedValue.SetNull()
    this.vType = VM_ValueType.vmNULL
    vValue = 0
end sub

sub VM_BoxedValue.SetInteger(i as longint)
    this.vType = VM_ValueType.vmINT
    *cptr(longint ptr,@vValue) = i
end sub

sub VM_BoxedValue.SetBoolean(i as unsigned byte)
    this.vType = VM_ValueType.vmBOOL
    *cptr(unsigned byte ptr,@vValue) = iif(i<>0,1,0)
end sub

sub VM_BoxedValue.SetReal(i as double)
    this.vType = VM_ValueType.vmREAL
    *cptr(double ptr,@vValue) = i
end sub

sub VM_BoxedValue.SetFunction(i as unsigned longint)
    this.vType = VM_ValueType.vmFUNC
    vValue = i
end sub

sub VM_BoxedValue.SetString(s as VM_String ptr)
    this.vType = VM_ValueType.vmString
    vValue = cuint(s)
end sub

sub VM_BoxedValue.SetPtr(t as VM_ValueType,p as any ptr)
    this.vType = t
    *cptr(any ptr ptr,@vValue) = p
end sub

function VM_BoxedValue.GetInteger() as longint
    select case this.vType
        case VM_ValueType.vmNULL:
            return 0
        case VM_ValueType.vmBOOL:
            return iif(*cptr(unsigned byte ptr,@vValue)<>0 ,1,0)
        case VM_ValueType.vmINT
            return *cptr(longint ptr,@vValue)
        case VM_ValueType.vmREAL
            return int(*cptr(double ptr,@vValue))
        case VM_ValueType.vmSTRING
            return 0
        case VM_ValueType.vmTABLE
            return 0
        case VM_ValueType.vmOBJ
            return 0
        case VM_ValueType.vmFUNC
            return *cptr(unsigned long ptr,@vValue)
    end select
end function


function VM_BoxedValue.GetReal() as double
    select case this.vType
        case VM_ValueType.vmNULL:
            return 0
        case VM_ValueType.vmBOOL:
            return iif(*cptr(unsigned byte ptr,@vValue)<>0 ,1,0)
        case VM_ValueType.vmINT
            return *cptr(longint ptr,@vValue)
        case VM_ValueType.vmREAL
            return *cptr(double ptr,@vValue)
        case VM_ValueType.vmSTRING
            return 0
        case VM_ValueType.vmTABLE
            return 0
        case VM_ValueType.vmOBJ
            return 0
        case VM_ValueType.vmFUNC
            return *cptr(unsigned long ptr,@vValue)
    end select
end function

function VM_BoxedValue.GetBoolean() as unsigned byte
    select case this.vType
        case VM_ValueType.vmNULL:
            return 0
        case VM_ValueType.vmBOOL:
            if *cptr(unsigned byte ptr,@vValue)<>0 then return 1
        case VM_ValueType.vmINT
            if *cptr(longint ptr,@vValue)<>0 then return 1
        case VM_ValueType.vmREAL
            if *cptr(double ptr,@vValue)<>0 then return 1
        case VM_ValueType.vmSTRING
            if (vValue<>0) then return 1
        case VM_ValueType.vmTABLE
            if (vValue<>0) then return 1
        case VM_ValueType.vmOBJ
            if (vValue<>0) then return 1
        case VM_ValueType.vmFUNC
            if (vValue<>0) then return 1
    end select
    
    return 0
end function

function VM_BoxedValue.GetString() as unsigned byte ptr
	select case this.vType
		case VM_ValueTYpe.vmSTRING
			return cptr(VM_STRING ptr,cuint(this.vValue))->Buffer
	end select
	return 0
end function

function VM_BoxedValue.GetPtr() as any ptr
    if (this.vType = VM_ValueType.vmTABLE) or _
       (this.vType = VM_ValueType.vmSTRING) or _
       (this.vType = VM_ValueType.vmGC) then
        return cptr(any ptr,cuint(this.vValue))
    end if
    return 0
end function

function VM_BoxedValue.IsNumeric() as boolean
    return (this.vType = VM_ValueType.vmINT) or (this.vType = VM_ValueType.vmREAL)   
end function

sub VM_BoxedValue.DoAdd(owner as any ptr,vdest as VM_BoxedValue ptr,v1 as VM_BoxedValue ptr,v2 as VM_BoxedValue ptr)
    if (v1<>0 and v2<>0) then
        if (v1->vType = VM_ValueType.vmNULL or v2->vType = VM_ValueType.vmNULL) then
            vdest->SetNull()
                return
        end if
        
        if (v1->vType = VM_ValueType.vmBOOL or v2->vType=VM_ValueType.vmBool) then
            vdest->SetBoolean( v1->GetBoolean() or v2->GetBoolean())
            return
        end if
        
        if (v1->IsNumeric() and v2->IsNumeric()) then
            if (v1->vType = VM_ValueType.vmREAL or v2->vType = VM_ValueType.vmREAL) then
                vdest->SetReal(v1->getReal() + v2->getReal())
                return
            else
                vdest->SetInteger(v1->getInteger() + v2->getInteger())
                return
            end if
        end if
        
        if (v1->vType = VM_ValueType.vmFUNC) and (v1->vType = VM_ValueType.vmFUNC) then
            vdest->SetFunction(v1->vValue + v2->vValue)
            return
        end if
        if (v1->vType = VM_ValueType.vmFUNC) and (v2->IsNumeric()) then
            vdest->SetFunction(v1->vValue + v2->GetInteger())
            return
        end if
        if (v2->vType = VM_ValueType.vmFUNC) and (v1->IsNumeric()) then
            vdest->SetFunction(v2->vValue + v1->GetInteger())
            return
        end if
        if (v1->vTYPE = VM_ValueType.vmSTRING) and (v2->vType = VM_ValueType.vmSTRING) then
            var vs1 = cptr(VM_STRING ptr,cuint(v1->vValue))
            var vs2 = cptr(VM_STRING ptr,cuint(v2->vValue))
            var ns = VM_STRING.Create(owner,strcat(vs1->BUFFER,vs2->BUFFER))
            vdest->SetString(ns)
            return
        end if
         if (v1->vTYPE = VM_ValueType.vmSTRING) and (v2->vType = VM_ValueType.vmINT) then
            var vs1 = cptr(VM_STRING ptr,cuint(v1->vValue))
            var ns  = VM_STring.Create(owner,strcat(vs1->Buffer,IntToSTR(cast(longint,v2->vValue),10)))
            vdest->SetString(ns)
            return
        end if
        'todo: adding value to an object=>check override operator
        'todo: adding value to a string=>concatenate both values as string
        'todo: adding value to a table=>???
    end if
    vdest->SetNull()
end sub

sub VM_BoxedValue.DoSub(owner as any ptr,vdest as VM_BoxedValue ptr,v1 as VM_BoxedValue ptr,v2 as VM_BoxedValue ptr)
    if (v1<>0 and v2<>0) then
        if (v1->vType = VM_ValueType.vmNULL or v2->vType = VM_ValueType.vmNULL) then
            vdest->SetNull()
                return
        end if
        
        if (v1->vType = VM_ValueType.vmBOOL or v2->vType=VM_ValueType.vmBool) then            
            vdest->SetBoolean( v1->GetBoolean() xor v2->GetBoolean())
            return
        end if
        
        if (v1->IsNumeric() and v2->IsNumeric()) then
            if (v1->vType = VM_ValueType.vmREAL or v2->vType = VM_ValueType.vmREAL) then
                vdest->SetReal(v1->getReal() - v2->getReal())
                return
            else
                vdest->SetInteger(v1->getInteger() - v2->getInteger())
                return
            end if
        end if
        
        if (v1->vType = VM_ValueType.vmFUNC) and (v1->vType = VM_ValueType.vmFUNC) then
            vdest->SetFunction(v1->vValue - v2->vValue)
            return
        end if
        if (v1->vType = VM_ValueType.vmFUNC) and (v2->IsNumeric()) then
            vdest->SetFunction(v1->vValue - v2->GetInteger())
            return
        end if
        if (v2->vType = VM_ValueType.vmFUNC) and (v1->IsNumeric()) then
            vdest->SetFunction(v2->vValue - v1->GetInteger())
            return
        end if
        if (v1->vType = VM_ValueType.vmSTRING) and (v2->vType = VM_ValueType.vmSTRING) then
            var s1 = cptr(VM_String ptr,cuint(v1->vValue))
            var s2 = cptr(VM_String ptr,cuint(v2->vValue))
            vdest->setInteger(s1->CompareTo(s2))
        end if
        'todo: adding value to an object=>check override operator
        'todo: adding value to a string=>concatenate both values as string
        'todo: adding value to a table=>???
    end if
    vdest->SetNull()
end sub


sub VM_BoxedValue.DoMul(owner as any ptr,vdest as VM_BoxedValue ptr,v1 as VM_BoxedValue ptr,v2 as VM_BoxedValue ptr)
    if (v1<>0 and v2<>0) then
        if (v1->vType = VM_ValueType.vmNULL or v2->vType = VM_ValueType.vmNULL) then
            vdest->SetNull()
                return
        end if
        
        if (v1->vType = VM_ValueType.vmBOOL or v2->vType=VM_ValueType.vmBool) then
            vdest->SetBoolean( v1->GetBoolean() and v2->GetBoolean())
            return
        end if
        
        if (v1->IsNumeric() and v2->IsNumeric()) then
            if (v1->vType = VM_ValueType.vmREAL or v2->vType = VM_ValueType.vmREAL) then
                vdest->SetReal(v1->getReal() * v2->getReal())
                return
            else
                vdest->SetInteger(v1->getInteger() * v2->getInteger())
                return
            end if
        end if
        
        if (v1->vType = VM_ValueType.vmFUNC) and (v1->vType = VM_ValueType.vmFUNC) then
            vdest->SetFunction(v1->vValue * v2->vValue)
            return
        end if
        if (v1->vType = VM_ValueType.vmFUNC) and (v2->IsNumeric()) then
            vdest->SetFunction(v1->vValue * v2->GetInteger())
            return
        end if
        if (v2->vType = VM_ValueType.vmFUNC) and (v1->IsNumeric()) then
            vdest->SetFunction(v2->vValue * v1->GetInteger())
            return
        end if
        'todo: adding value to an object=>check override operator
        'todo: adding value to a string=>concatenate both values as string
        'todo: adding value to a table=>???
    end if
    vdest->SetNull()
end sub



sub VM_BoxedValue.DoDiv(owner as any ptr,vdest as VM_BoxedValue ptr,v1 as VM_BoxedValue ptr,v2 as VM_BoxedValue ptr)
    if (v1<>0 and v2<>0) then
        if (v1->vType = VM_ValueType.vmNULL or v2->vType = VM_ValueType.vmNULL) then
            vdest->SetNull()
                return
        end if
        
        if (v1->vType = VM_ValueType.vmBOOL or v2->vType=VM_ValueType.vmBool) then
            vdest->SetBoolean( v1->GetBoolean() and v2->GetBoolean())
            return
        end if
        
        if (v1->IsNumeric() and v2->IsNumeric()) then
            if (v1->vType = VM_ValueType.vmREAL or v2->vType = VM_ValueType.vmREAL) then
                vdest->SetReal(v1->getReal() / v2->getReal())
                return
            else
                vdest->SetInteger(v1->getInteger() / v2->getInteger())
                return
            end if
        end if
        
        if (v1->vType = VM_ValueType.vmFUNC) and (v1->vType = VM_ValueType.vmFUNC) then
            vdest->SetFunction(v1->vValue / v2->vValue)
            return
        end if
        if (v1->vType = VM_ValueType.vmFUNC) and (v2->IsNumeric()) then
            vdest->SetFunction(v1->vValue / v2->GetInteger())
            return
        end if
        if (v2->vType = VM_ValueType.vmFUNC) and (v1->IsNumeric()) then
            vdest->SetFunction(v2->vValue / v1->GetInteger())
            return
        end if
        'todo: adding value to an object=>check override operator
        'todo: adding value to a string=>concatenate both values as string
        'todo: adding value to a table=>???
    end if
    vdest->SetNull()
end sub


sub VM_BoxedValue.DoInc(owner as any ptr,vdest as VM_BoxedValue ptr,v1 as VM_BoxedValue ptr)
    if (v1<>0) then
        select case v1->vType
            case VM_ValueType.vmBOOL
                vdest->SetBoolean(1)
            case VM_ValueType.vmNULL
                vdest->SetNull
            case VM_ValueType.vmREAL
                vdest->SetReal(v1->getReal()+1)
            case VM_ValueType.vmINT
                vdest->SetInteger(v1->getInteger()+1)
            case VM_ValueType.vmFUNC
                vdest->SetFunction(v1->vValue+1)
            case else
                vdest->SetBoxed(v1)
        end select
        return
    end if
    vdest->SetNull()
end sub

sub VM_BoxedValue.DoDec(owner as any ptr,vdest as VM_BoxedValue ptr,v1 as VM_BoxedValue ptr)
    if (v1<>0) then
        select case v1->vType
            case VM_ValueType.vmBOOL
                vdest->SetBoolean(v1->getBoolean() xor 1)
            case VM_ValueType.vmNULL
                vdest->SetNull
            case VM_ValueType.vmREAL
                vdest->SetReal(v1->getReal()-1)
            case VM_ValueType.vmINT
                vdest->SetInteger(v1->getInteger()-1)
            case VM_ValueType.vmFUNC
                vdest->SetFunction(v1->vValue-1)
            case else
                vdest->SetBoxed(v1)
        end select
        return
    end if
    vdest->SetNull()
end sub

function VM_BoxedValue.Equals(v1 as VM_BoxedValue ptr,v2 as VM_BoxedValue ptr) as boolean
    'null values always returns null
    if (v1 = 0) and (v2 = 0) then return false
    if (v1 = 0) and (v2 <> 0) then return false
    if (v1 <> 0) and (v2 = 0) then return false
    
    if (v1->vType = VM_ValueTYpe.vmNULL) and (v2->vType <> VM_ValueType.vmNULL) then return false
    if (v1->vType <> VM_ValueTYpe.vmNULL) and (v2->vType = VM_ValueType.vmNULL) then return false
    'except compare null to null
    if (v1->vType = VM_ValueType.vmNULL) and (v2->vType = VM_ValueType.vmNULL)  then return true
    

    
    'compare a reference type with another type with always returns false
    if (v1->vType = VM_ValueType.vmSTRING) and (v2->vTYPE <> VM_ValueType.vmString) then return false
    if (v1->vType <> VM_ValueType.vmSTRING) and (v2->vTYPE = VM_ValueType.vmString) then return false
    if (v1->vType = VM_ValueType.vmTABLE) and (v2->vType <> VM_ValueType.vmTABLE)   then return false
    if (v1->vType <> VM_ValueType.vmTABLE) and (v2->vType = VM_ValueType.vmTABLE)   then return false
    if (v1->vType = VM_ValueType.vmOBJ) and (v2->vType <> VM_ValueType.vmOBJ)   then return false
    if (v1->vType <> VM_ValueType.vmOBJ) and (v2->vType = VM_ValueType.vmOBJ)   then return false
    
    'for non comparables references types, equalty = same address
    if (v1->vType = VM_ValueType.vmFUNC) and (v2->vType = VM_ValueType.vmFUNC) then return v1->vValue = v2->vValue
    if (v1->vType = VM_ValueType.vmOBJ) and (v2->vType = VM_ValueType.vmOBJ) then return v1->vValue = v2->vValue
    if (v1->vType = VM_ValueType.vmTable) and (v2->vType = VM_ValueType.vmTable) then return v1->vValue = v2->vValue
    
    'compare something with a boolean will always return (booleanvalue) = (non zero)
    'true with 0 => false
    'true with &hxxx => true
    'false with 0 => true
    'false with &hxxxx => false
    if (v1->vType = VM_ValueType.vmBOOL) or (v2->vType = VM_ValueType.vmBool) then return v1->GetBoolean() = v2->GetBoolean()
    
    'compare Twoo numerics
    if (v1->IsNumeric()) and (v2->IsNumeric()) then
        'compare a real with an integer will use the real representation
        if (v1->vType = VM_ValueType.vmREAL) or (v2->vType = VM_ValueType.vmReal) then return v1->GetReal() = v2->GetReal()
        'compare twoo integers
        return v1->GetInteger() = v2->GetInteger()
    end if
    
    'compare twoo string
    if (v1->vType = VM_ValueType.vmString) and (v2->vType = VM_ValueType.vmString) then
        'both are identical
        if (v1->vValue = v2->vValue) then return true
        
        'do a string compare
        var vstring1 = cptr(VM_STRING ptr,cuint(v1->vValue))
        var vstring2 = cptr(VM_STRING ptr,cuint(v2->vValue))
        return vstring1->Equals(vstring2)
    end if
    
    return 0
end function