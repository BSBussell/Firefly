extends Platform

enum SPRITE_TYPE {
	PLAIN,
	RIGHT,
	UPWARD
}

@export var sprite_variant: SPRITE_TYPE

@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var sparkles: CPUParticles2D = $sparkles
@onready var animation_player = $PointLight2D/AnimationPlayer
@onready var activate_audio = $Audio/activate



var activated: bool = false

var prefix: String = "plain_"


func child_ready():
	
	match sprite_variant:
		SPRITE_TYPE.PLAIN:
			prefix = "plain_"
		SPRITE_TYPE.RIGHT:
			prefix = "right_"
		SPRITE_TYPE.UPWARD:
			prefix = "up_"
			
	animated_sprite_2d.play(prefix + "shimmer")

func flip_sprite(dir: bool):
	animated_sprite_2d.flip_h = dir

func activate():
	animated_sprite_2d.play(prefix + "activate")
	animation_player.play("light_up")
	activated = true
	sparkles.amount = 32

func deactivate():
	animated_sprite_2d.play(prefix + "deactivate")
	animation_player.play("dim")
	activated = false
	sparkles.amount = 16  


func _on_animated_sprite_2d_animation_finished():
	if activated:
		animated_sprite_2d.play(prefix + "activate_shimmer")
	else:
		animated_sprite_2d.play(prefix + "shimmer")


func _on_player_landed(player):
	if not activated: 
		activate_audio.play() 
