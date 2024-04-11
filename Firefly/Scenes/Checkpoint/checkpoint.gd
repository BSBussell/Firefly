extends Node2D
class_name CheckPoint

var active = false

@export var optional_target: Marker2D = null

@onready var checkpoint_sprite = $CheckpointSprite
@onready var spotlight = $Spotlight
@onready var explode = $explode
@onready var lightparticles = $lightparticles

var manager: CheckPointManager

# Called when the node enters the scene tree for the first time.
func _ready():
	spotlight.set_brightness(0)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_checkpoint_area_area_entered(area):
	pass
	#checkpoint_sprite.set_frame(1)
	#spotlight.energy = 1
	#explode.emitting = true
	#lightparticles.emitting = true
	#area.checkpoint_entered()


func _on_checkpoint_area_body_entered(body):
	
	var player = body as Flyph
	if player and not active:
		activate_checkpoint(player)
		
	else:
		print("Potential Enemy or something else :3")


func set_manager(manager: CheckPointManager):
	self.manager = manager

## Activates the Checkpoint
func activate_checkpoint(player: Flyph):
	checkpoint_sprite.set_frame(1)
	spotlight.set_brightness(0.6)
	explode.emitting = true
	lightparticles.emitting = true
	
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
