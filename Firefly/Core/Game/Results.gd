extends Node
class_name VictoryScreen

signal Show_Victory()
@onready var color_rect = $ColorRect
@onready var stats_label = $ColorRect/VBoxContainer/CenterContainer2/Stats

var displayed: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	if not get_tree().paused:
		_stats.TIME += delta

	var minutes: int = int(_stats.TIME) / 60
	var seconds: int = int(_stats.TIME) % 60
	var milliseconds: int = int((_stats.TIME - int(_stats.TIME)) * 1000)

	var display_time = "%02d:%02d:%03d" % [minutes, seconds, milliseconds]

	stats_label.text = "Time: %s\n Total Deaths: %d" % [display_time, _stats.DEATHS]

func show_Victory_Screen():
	color_rect.visible = true
	get_tree().paused = true
	displayed = true

func hide_Victory_Screen():
	color_rect.visible = false
	displayed = false
