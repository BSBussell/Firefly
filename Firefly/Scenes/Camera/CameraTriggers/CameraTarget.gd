class_name CameraTarget
extends Area2D

@export var pull_strength: float = 1.0
@export var blend_priority: int = -1
@export var blend_override: float = 0.3

func enable_target():
	
	set_collision_layer_value(7, true)

func disable_target():
	
	set_collision_layer_value(7, false)
