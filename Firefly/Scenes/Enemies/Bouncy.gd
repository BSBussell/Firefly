extends Spring

@onready var walking_enemy = $".."
@onready var squish_node = $"../SquishNode"


func spring_up_fx() -> void:
	
	
	sprite_2d.frame = 4
	squish_node.squish(Vector2(1.5,0.5))
	pass

func spring_down_fx() -> void:
	

	
	print("SPring Down Fx?")
	pass


