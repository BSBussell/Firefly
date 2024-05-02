extends ColorRect

@onready var animation_player = $AnimationPlayer


func play_animation(animation: String):
	animation_player.play(animation)
