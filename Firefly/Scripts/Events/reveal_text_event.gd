# reveal_text_event.gd
extends "res://Scripts/Events/base_event.gd"

@export var Text: Control

func _ready():
	Text.visible = false
	
	# Enabling and disabling the physics process method
	# In order to decrease unecessary checks and stuff
	# Cause Im cute like that
	set_physics_process(false)
	

func _physics_process(delta):
	
	# Check if we're on floor
	if enter_body and enter_body.is_on_floor():
		Text.visible = true
		set_physics_process(false)

func on_enter(body):
	set_physics_process(true)

func on_exit(body):
	Text.visible = false
