extends "res://Scripts/Events/base_event.gd"

@onready var Sprite = $Sprite2D
@onready var animation_player = $AnimationPlayer
@export var point_value = 0.0

func _ready():
	animation_player.play("Idle")

func on_enter(body: Flyph):
	body.add_glow(point_value)
	animation_player.play("Grab")
	_ui.new_item_found()
