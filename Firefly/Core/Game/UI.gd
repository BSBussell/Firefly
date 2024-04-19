# UIScript.gd
extends Node

@onready var label = $UIViewPort/Results/ColorRect/VBoxContainer/CenterContainer2/Label
@onready var pause_menu = $UIViewPort/Pause
@onready var color_rect = $UIViewPort/Results/ColorRect


func _ready():
	
	# Global UI Elements
	_ui.COUNTER = $UIViewPort/Results/Label
	_ui.COUNTER_ANIMATOR = $UIViewPort/Results/AnimationPlayer
	_ui.ANIMATION_TIMER = $UIViewPort/Results/HideTimer
	_ui.connect_timer()

	_ui.Victory = $UIViewPort/Results/ColorRect
	
func _process(delta):
	
	if not get_tree().paused:
		_stats.TIME += delta

	var minutes: int = int(_stats.TIME) / 60
	var seconds: int = int(_stats.TIME) % 60
	var milliseconds: int = int((_stats.TIME - int(_stats.TIME)) * 1000)

	var display_time = "%02d:%02d:%03d" % [minutes, seconds, milliseconds]

	label.text = "Time: %s\n Total Deaths: %d" % [display_time, _stats.DEATHS]


func toggle_pause_menu():
	if not color_rect.visible:
		pause_menu.visible = !pause_menu.visible
		get_tree().paused = !get_tree().paused

func hide_color_rect():
	color_rect.hide()

func show_color_rect():
	color_rect.show()
