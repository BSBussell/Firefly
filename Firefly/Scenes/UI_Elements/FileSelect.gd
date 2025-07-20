extends Control
class_name FileSelectScene

@export var save_container: SaveContainer

@export var scroll_container: ScrollContainer

@onready var animation_player = $AnimationPlayer

signal Closing

# Called when the node enters the scene tree for the first time.
func _ready():
	pivot_offset = size/2

func _unhandled_input(_event):
	
	if visible and Input.is_action_pressed("ui_cancel"):
		
		animation_player.play("close")
		
		await animation_player.animation_finished
		emit_signal("Closing")

	#if Input.is_action_just_pressed("ui_accept"):
		#print("Focus Owner:", get_viewport().gui_get_focus_owner())


func load_in():
	animation_player.play("load_in")
	
	await animation_player.animation_finished 
	save_container.get_child(0).grab_focus()
	scroll_container.scroll_vertical = 0
