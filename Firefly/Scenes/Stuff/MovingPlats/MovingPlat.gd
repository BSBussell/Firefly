extends Node2D
class_name MovingPlat

@export var speed_scale: float = 1.0
@export var closed: bool = false

@export_category("Protected Variables")
@export_group("Only touch in child classes")
@export var animation_player: AnimationPlayer
@export var progress_node: PathFollow2D


# Called when the node enters the scene tree for the first time.
func _ready():
	
	if animation_player and progress_node:
		
		
		
		animation_player.speed_scale = speed_scale
		
		if closed:
			animation_player.play("closed")
			progress_node.loop = true
		else:
			animation_player.play("open")
			progress_node.loop = false
	else:
		printerr("FAILED TO SETUP PROTECTED VARIABLES IN: ", self.name)



func  _process(delta):
	
	if progress_node:
		progress_node.progress = floor(progress_node.progress)
