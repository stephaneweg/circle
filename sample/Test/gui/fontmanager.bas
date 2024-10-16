dim shared FontManager as TFontManager

function GetFontManager() as TFontManager ptr
	return @FontManager
end function

sub TFontManager.Init()
    this.ML = LoadFont(@"ML")
    this.SMALL = LoadFont(@"SMALL")
    this.M = LoadFont(@"M")
	this.SIMPAGAR = LoadFont(@"SIMPAGAR")
	this.F8X8		= LoadFont(@"8X8")
end sub