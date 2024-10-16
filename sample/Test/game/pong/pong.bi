declare sub Pong_Update(g as Application ptr,state as GameState ptr)
declare sub Pong_Redraw(g as Application ptr,root as GUI_ELEMENT ptr)
declare sub Pong_Exit(g as Application ptr)
declare function app_main cdecl alias "app_main"(root as GUI_Element ptr) as Application ptr


type Pong extends Application field=1
	dim player1_y as double
	dim player2_y as double
	
	dim ViewPort_Height as double
	dim ViewPort_Width as double
	
	dim player1_bar_size as double
	dim player2_bar_size as double
	
	dim ball_position_x as double
	dim ball_position_y as double
	dim ball_direction_x as double
	dim ball_direction_y as double
	dim ball_radius as double
	
	dim player_margin as double
	dim bar_thickness as double
	
	dim started as integer
	dim waitFor as integer
	
	dim player1_points as integer
	dim player2_points as integer
	
	dim ball_speed as double
	
	declare constructor()
	declare sub RecenterBars()
	declare sub ResetBallPos()
end type