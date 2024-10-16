#include once "../../system.bi"
#include once "../../gui/gui.bi"
#include once "../game.bi"
#include once "../../app.bi"
#include once "pong.bi"



function app_main cdecl alias "app_main"(root as GUI_Element ptr) as Application ptr
	dim pongGame as Pong ptr  = new Pong()
	
	pongGame->ball_speed = 100
	pongGame->player_margin = 20
	pongGame->bar_thickness = 10
	
	
	
	pongGame->ViewPort_Height = root->Height
	pongGame->ViewPort_Width = root->Width
	pongGame->player1_bar_size = 150
	pongGame->player2_bar_size = 150
	pongGame->started = 0
	pongGame->WaitFor = 0
	pongGame->ball_radius = 10
	
	pongGame->player1_points = 0
	pongGame->player2_points = 0
	
	pongGame->RecenterBars()
	pongGame->ResetBallPos()
	
	return pongGame
end function


constructor Pong()
	this.OnUpdate=@Pong_Update
	this.OnRedraw=@Pong_Redraw
	this.OnExit=@Pong_Exit
end constructor

sub Pong.RecenterBars()
	player1_Y = (Viewport_Height - player1_bar_size)/2
	player2_y = (Viewport_Height - player2_bar_size)/2
end sub

sub Pong.ResetBallPos()
	
	ball_position_y = ViewPort_Height/2
	if (waitFor = 0) then
		ball_position_x = player_margin + bar_thickness+ball_radius+2
		ball_direction_x = 0
		ball_direction_y = 0
	else	
		ball_position_x = viewport_Width - player_margin - bar_thickness - ball_radius-3
		ball_direction_x = 0
		ball_direction_y = 0
	end if

end sub

sub Pong_Update(g as Application ptr,state as GameState ptr)
	dim pongGame as Pong ptr = cptr(Pong ptr,g)

	dim speed as double = (200 * state->elapsed)
	dim ballSpeed as double = pongGame->ball_speed * state->elapsed
	
	dim player1_move as integer = state->controller(0).vertical_movement
	dim player2_move as integer = state->controller(1).vertical_movement
	
	
	pongGame->player1_y += player1_move*speed 
	pongGame->player2_y += player2_move*speed
	
	if (pongGame->player1_y<0) then pongGame->player1_y = 0
	if (pongGame->player2_y<0) then pongGame->player2_y = 0
	
	if (pongGame->player1_y+pongGame->player1_bar_size >= pongGame->ViewPort_Height) then pongGame->player1_y = pongGame->ViewPort_Height-pongGame->player1_bar_size
	if (pongGame->Player2_y+pongGame->player2_bar_size >= pongGame->ViewPort_Height) then pongGame->player2_y = pongGame->ViewPort_Height-pongGame->player2_bar_size
	
	
	if (pongGame->started = 0) then
		if (pongGame->waitFor=0) then
			pongGame->ball_position_y = pongGame->player1_Y+pongGame->player1_bar_size/2
		else
			pongGame->ball_position_y = pongGame->player2_Y+pongGame->player2_bar_size/2
		end if
		
		
		if (state->controller(pongGame->waitFor).button0=1) then
			if (pongGame->waitFor = 0) then
				pongGame->ball_direction_y = player1_move
				pongGame->ball_direction_x = 1
				pongGame->waitFor = 1
			else
				pongGame->ball_direction_y = player2_move
				pongGame->ball_direction_x = -1
				pongGame->waitFor = 0
			end if
			
			pongGame->started = 1
		end if
	end if
	
	
	
	
	if (pongGame->started=1) then
		
	
		dim p1_x1 as double  = pongGame->player_margin
		dim p1_x2 as double = p1_x1 + pongGame->bar_thickness
		dim p1_y1 as double = pongGame->player1_Y
		dim p1_y2 as double = p1_y1 + pongGame->player1_bar_size
		
		dim p2_x2 as double = pongGame->Viewport_Width - pongGame->player_margin-1
		dim p2_x1 as double = p2_x2 - pongGame->bar_thickness
		dim p2_y1 as double = pongGame->player2_y
		dim p2_y2 as double = p2_y1 + pongGame->player2_bar_size
	
	
		pongGame->ball_position_x += pongGame->ball_direction_x*ballSpeed
		pongGame->ball_position_y += pongGame->ball_direction_y*ballSpeed
		
		dim b_x1 as double = pongGame->ball_position_x - pongGame->ball_radius
		dim b_x2 as double = pongGame->ball_position_x + pongGame->ball_radius
		dim b_y1 as double = pongGame->ball_position_y - pongGame->ball_radius
		dim b_y2 as double = pongGame->ball_position_y + pongGame->ball_radius
		
		if (pongGame->ball_position_x <= pongGame->ball_radius) then
			pongGame->player2_points += 1
			pongGame->started = 0
			pongGame->WaitFor = 1
			pongGame->RecenterBars()
			pongGame->ResetBallPos()
			pongGame->ball_speed = 100
		elseif (pongGame->ball_position_x >= (pongGame->ViewPort_Width-pongGame->ball_radius-1)) then
			pongGame->player1_points += 1
			pongGame->started = 0
			pongGame->WaitFor = 0
			pongGame->RecenterBars()
			pongGame->ResetBallPos()
			pongGame->ball_speed = 100
		elseif (pongGame->ball_position_y<= pongGame->ball_radius) then
			pongGame->ball_direction_y = 1
		elseif (pongGame->ball_position_y>=pongGame->Viewport_Height-pongGame->ball_radius-1) then
			pongGame->ball_direction_y = -1
		elseif b_x1<p1_x2 and b_x2>p1_x1 and b_y1<p1_y2 and b_y2> p1_y1 then
			pongGame->ball_direction_x = 1
            pongGame->ball_direction_y += player1_move
			pongGame->ball_speed+=10
		elseif b_x1<p2_x2 and b_x2>p2_x1 and b_y2<p2_y2 and b_y2> p2_y1 then
			pongGame->ball_direction_x = -1
            pongGame->ball_direction_y += player2_move
			pongGame->ball_speed+=10
		end if
		
	end if
end sub

sub Pong_Redraw(g as Application ptr,root as GUI_ELEMENT ptr)
	dim pongGame as Pong ptr = cptr(Pong ptr,g)
	
	dim p1_x1 as double  = pongGame->player_margin
	dim p1_x2 as double = p1_x1 + pongGame->bar_thickness
	dim p2_x2 as double = pongGame->Viewport_Width - pongGame->player_margin-1
	dim p2_x1 as double = p2_x2 - pongGame->bar_thickness
	dim p1_y1 as double = pongGame->player1_Y
	dim p1_y2 as double = p1_y1 + pongGame->player1_bar_size
	dim p2_y1 as double = pongGame->player2_y
	dim p2_y2 as double = p2_y1 + pongGame->player2_bar_size
	
	dim b_x1 as double = pongGame->ball_position_x - pongGame->ball_radius
	dim b_x2 as double = pongGame->ball_position_x + pongGame->ball_radius
	dim b_y1 as double = pongGame->ball_position_y - pongGame->ball_radius
	dim b_y2 as double = pongGame->ball_position_y + pongGame->ball_radius
	
	root->FillRectangle(p1_x1,p1_y1,p1_x2,p1_y2,&hFF0000)
	root->FillRectangle(p2_x1,p2_y1,p2_x2,p2_y2,&h0000FF)
	root->FillRectangle(b_x1,b_y1,b_x2,b_y2,&hFFF000)
	
end sub

sub Pong_Exit(g as Application ptr)

end sub