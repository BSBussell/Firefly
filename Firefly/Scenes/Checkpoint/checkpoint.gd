extends Node2D

@onready var checkpoint_sprite = $CheckpointSprite

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_checkpoint_area_area_entered(area):
	checkpoint_sprite.set_frame(1)
