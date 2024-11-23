extends "res://Scenes/Camera/CameraTriggers/CameraTarget.gd"
class_name CheckPoint

var active = false

@export var optional_target: Marker2D = null
@export var secret: bool = false

@onready var checkpoint_sprite = $CheckpointSprite
@onready var spotlight = $Spotlight
@onready var explode = $explode
@onready var lightparticles = $lightparticles
@onready var check_point_lit = $CheckPointLit


var manager: CheckPointManager

var id: String



# Called when the node enters the scene tree for the first time.
func _ready():
	spotlight.set_brightness(0)
	id = _globals.gen_id(global_position)
	
	if secret:
		visible = false


func set_manager(checkpoint_manager: CheckPointManager):
	manager = checkpoint_manager

## Activates the Checkpoint
func activate_checkpoint(player: Flyph):
	
	# If this isn't a hidden checkpoint play fx
	if not secret:
		checkpoint_sprite.set_frame(1)
		spotlight.set_brightness(0.6)
		explode.emitting = true
		lightparticles.emitting = true
		check_point_lit.play()
	
	# If a target is defined use that for respawn
	if optional_target:
		player.set_respawn_point(optional_target.global_position)
	
	# Otherwise just use the players current position
	else:
		player.set_respawn_point(player.global_position)
		
	
		
		
		
	active = true
	manager.update_Active(self)

## Deactivates the checkpoint
func deactivate_checkpoint():
	checkpoint_sprite.set_frame(0)
	spotlight.set_brightness(0.0)
	lightparticles.emitting = false
	active = false




func _on_body_entered(body):
	var player = body as Flyph
	if player and not active:
		activate_checkpoint(player)
