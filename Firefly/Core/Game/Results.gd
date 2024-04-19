extends Node
class_name VictoryScreen

signal Show_Victory()
@onready var color_rect = $ColorRect

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func show_Victory_Screen():
	color_rect.visible = true
	get_tree().paused = true

func hide_Victory_Screen():
	color_rect.visible = false
