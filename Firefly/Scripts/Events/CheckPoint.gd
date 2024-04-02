extends "res://Scripts/Events/base_event.gd"

func _ready():
	set_physics_process(false)

func _physics_process(_delta):
	if enter_body and enter_body.is_on_floor():
		
		var player: Flyph = enter_body as Flyph
		player.starting_position = player.global_position
		
		
		set_physics_process(false)

func on_enter(_body):
	
	var player: Flyph = _body as Flyph
	if not player:
		print("ah shit")
		
	set_physics_process(true)

func on_exit(_body):
	pass





