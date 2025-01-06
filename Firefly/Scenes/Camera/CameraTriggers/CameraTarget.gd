class_name CameraTarget
extends Area2D

## How much weight the target will have when averaged with other targets
@export var pull_strength: float = 1.0

## How much of a priority the targets "blend_override" will be relative to
## other targets. -1 does not override the blend
@export var blend_priority: int = -1

## The location between the player and other targets that the camera will rest in.
## The camera will take the average location of all targets on screen, then it 
## will draw a line between the player to that location. The blend_override sets 
## What ratio from the player to that location the camera will center on, 0.0 is
## the player, 1.0 is the averaged location.
@export var blend_override: float = 0.3

func enable_target():
	
	set_collision_layer_value(7, true)

func disable_target():
	
	set_collision_layer_value(7, false)
