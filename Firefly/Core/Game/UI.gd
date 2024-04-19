# UIScript.gd
extends Node

@onready var label = $UIViewPort/Results/ColorRect/VBoxContainer/CenterContainer2/Label
@onready var pause_menu = $UIViewPort/Pause
@onready var color_rect = $UIViewPort/Results/ColorRect


func _ready():
	
	_ui.Victory = $UIViewPort/Results/ColorRect
	


func toggle_pause_menu():
	if not color_rect.visible:
		pause_menu.visible = !pause_menu.visible
		get_tree().paused = !get_tree().paused

func hide_color_rect():
	color_rect.hide()

func show_color_rect():
	color_rect.show()
