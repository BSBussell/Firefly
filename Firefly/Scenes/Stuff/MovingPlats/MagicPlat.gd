extends Platform


@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var sparkles: CPUParticles2D = $sparkles
@onready var animation_player = $PointLight2D/AnimationPlayer
@onready var activate_audio = $Audio/activate



var activated: bool = false

func activate():
	animated_sprite_2d.play("activate")
	animation_player.play("light_up")
	activated = true
	sparkles.amount = 32

func deactivate():
	animated_sprite_2d.play("deactivate")
	animation_player.play("dim")
	activated = false
	sparkles.amount = 16  


func _on_animated_sprite_2d_animation_finished():
	if activated:
		
		animated_sprite_2d.play("activate_shimmer")
	else:
		animated_sprite_2d.play("shimmer")


func _on_player_landed(player):
	if not activated: 
		activate_audio.play() 
