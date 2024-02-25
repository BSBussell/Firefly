class_name PlayerState
extends Node

var gravity: int = ProjectSettings.get_setting("physics/2d/default_gravity")

## Hold a reference to the parent so that it can be controlled by the state
var parent: Flyph

# Called on state entrance, setup
func enter() -> void:
	pass

# Called before exiting the state, cleanup
func exit() -> void:
	pass

# Processing input in this state, returns nil or new state
func process_input(_event: InputEvent) -> PlayerState:
	return null

# Processing Frames in this state, returns nil or new state
func process_frame(_delta: float) -> PlayerState:
	return null

# Processing Physics in this state, returns nil or new state
func process_physics(_delta: float) -> PlayerState:
	return null
	
func animation_end() -> PlayerState:
	return null
