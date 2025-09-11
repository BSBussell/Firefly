extends CPUParticles2D
class_name BurstParticle

@onready var animation_player = $AnimationPlayer

# Called when the node enters the scene tree for the first time.
func _ready():
	animation_player.play("free")
