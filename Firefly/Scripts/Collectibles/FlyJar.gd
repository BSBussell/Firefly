extends "res://Scripts/Events/base_event.gd"

@onready var Sprite = $Sprite2D
@onready var animation_player = $AnimationPlayer

func _ready():
	animation_player.play("Idle")

func on_enter(_body):
	animation_player.play("Grab")
	_ui.new_item_found()
