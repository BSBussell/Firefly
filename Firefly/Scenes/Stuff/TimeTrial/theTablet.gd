extends Node2D
class_name TheTablet

@onready var animation_player = $AnimationPlayer

func On():
	animation_player.play("On")
	
func Off():
	animation_player.play("Off")
