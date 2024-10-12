extends Control
class_name FileSelectScene

@export var save_container: SaveContainer

@onready var animation_player = $AnimationPlayer


signal Closing

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _unhandled_input(event):
	
	if Input.is_action_pressed("ui_cancel"):
		
		animation_player.play("close")
		
		await animation_player.animation_finished
		emit_signal("Closing")

	if Input.is_action_just_pressed("ui_accept"):
		print("Focus Owner:", get_viewport().gui_get_focus_owner())

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func load_in():
	animation_player.play("load_in")
	
	save_container.get_child(0).grab_focus()
