extends Node2D
class_name Cutscene

# Identification for save/load
@export var cutscene_id: String = "!!!CHANGE ME!!!"

# Cutscene trigger area
@export var trigger_area: Area2D

# Cutscene animation player
@export var anim_player: AnimationPlayer

# Cutscene animation name
@export var cutscene_animation_name: String

# 
var cutscene_over: bool = false

var player: Flyph = null

# Called when the node enters the scene tree for the first time.
func _ready():
	
	if is_instance_valid(trigger_area):
		trigger_area.body_entered.connect(_on_body_entered)

	# Stop processing until cutscene starts
	set_process(false)
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	# If player is null return with error
	if player == null:
		push_error("Cutscene.gd: Player is null")
		return

	# If player is on ground, play animation
	if player.is_on_floor():
		anim_player.play(cutscene_animation_name)
		set_process(false)


func _on_body_entered(body: Node) -> void:

			
	
	# Check body type
	var local_player: Flyph = body as Flyph
	if local_player == null:
		return

	if local_player.is_actor:
		return
		
	player = local_player

	# Else set process to true
	set_process(true)

	# Disable player control
	player.is_actor = true
	player.lock_h_dir(0, 0.1)

# Called by animation player at end of cutscene
func set_cutscene_over() -> void:
	cutscene_over = true

	# Re-enable player control
	if is_instance_valid(player):
		player.is_actor = false
		

	# Disable area so cutscene doesn't trigger again
	if is_instance_valid(trigger_area):
		trigger_area.set_deferred("monitoring", false)
		
