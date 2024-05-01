extends Control

@onready var animation_player = $AnimationPlayer
@onready var label = $Label


var title_text: String = "oop"

func set_title(title: String):
	
	title_text = title

# Called when the node enters the scene tree for the first time.
func _ready():
	label.text = title_text
	await get_tree().create_timer(1.0).timeout
	animation_player.play("Drop-In")


var animation_finished: bool = false
func _input(event):
	if animation_finished:
		await get_tree().create_timer(2.0).timeout
		animation_player.play("Fade-Out")
	

func _on_animation_player_animation_finished(anim_name):
	animation_finished = true
