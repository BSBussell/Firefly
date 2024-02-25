# reveal_text_event.gd
extends "res://Scripts/Events/base_event.gd"

@export var Text: Control
@onready var nice = $"Nice!"

func _ready():
	Text.visible = false
	
	# Enabling and disabling the physics process method
	# In order to decrease unecessary checks and stuff
	# Cause Im cute like that
	set_physics_process(false)
	

func _physics_process(_delta):
	
	# Check if we're on floor
	if enter_body and enter_body.is_on_floor():
		nice.play("drop_in")
		set_physics_process(false)

func on_enter(_body):
	set_physics_process(true)

func on_exit(_body):
	nice.play("fall_out")
