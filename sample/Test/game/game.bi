#include once "../gui/gui.bi"

Type GameController field = 1
	dim joypad_num as unsigned long
	
	dim vertical_axis as unsigned long
	dim vertical_sign as long
	dim horizontal_axis as unsigned long
	dim horizontal_sign as long
	
	dim horizontal_movement as long
	dim vertical_movement as long
	
	
	dim button0 as unsigned long
	dim button1 as unsigned long
	dim button2 as unsigned long
	dim button3 as unsigned long
	dim button4 as unsigned long
	dim button5 as unsigned long
	dim button6 as unsigned long
	dim button7 as unsigned long
	
	dim button8 as unsigned long
	dim button9 as unsigned long
	dim button10 as unsigned long
	dim button11 as unsigned long
	dim button12 as unsigned long
	dim button13 as unsigned long
	dim button14 as unsigned long
	dim button15 as unsigned long
	
end type

type GameState field = 1
	dim elapsed		as double
	dim controller(0 to 1)	as GameController
end type