extends "res://Scripts/Events/base_event.gd"

@onready var Sprite = $Sprite2D

func on_enter(_body):
	Sprite.hide()
