extends Node2D

@onready var checkpoint_sprite = $CheckpointSprite
@onready var spotlight = $Spotlight
@onready var explode = $explode
@onready var lightparticles = $lightparticles

# Called when the node enters the scene tree for the first time.
func _ready():
	spotlight.energy = 0


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_checkpoint_area_area_entered(area):
	checkpoint_sprite.set_frame(1)
	spotlight.energy = 1
	explode.emitting = true
	lightparticles.emitting = true
