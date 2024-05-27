extends Node2D

@export_category("Properties")
@export var TIME_TO_BREAK: float = 1.0
@export var TIME_TO_RESPAWN: float = 3.0

@export_category("Don't Touch")
@export_subgroup("Nodes")
@export var sprite_2d: Sprite2D
@export var break_time: Timer
@export var respawn_time: Timer
@export var collider: StaticBody2D

@onready var explosion = $Explosion
@onready var animation_player = $AnimationPlayer
@onready var snap = $Audio/Snap
@onready var crash = $Audio/Crash


## Player
var flyph: Flyph = null

var platform_ready: bool = true

# Called when the node enters the scene tree for the first time.
func _ready():
	break_time.wait_time = TIME_TO_BREAK
	break_time.wait_time = TIME_TO_RESPAWN
	pass


func _physics_process(delta):
	
	if flyph and flyph.is_on_floor():
		
		snap.play()
		break_time.start()
		animation_player.play("Shake")
		animation_player.speed_scale = 2
		flyph = null
		set_physics_process(false)


func _on_player_detection_body_entered(body):
	
	var player: Flyph = body as Flyph
	if player and platform_ready:
	
		flyph = player
		# Check if player is on platform
		set_physics_process(true)


func _on_player_detection_body_exited(body):
	if flyph:
		set_physics_process(false)
		flyph = null

func destroy_platform():
	
	animation_player.play("Break")
	#animation_player.speed_scale = 1
	
	#collider.set_collision_layer_value()
	collider.collision_layer = 0
	crash.play()
	respawn_time.start()
	platform_ready = false
	

func respawn_platform():
	
	animation_player.play("respawn")
	collider.collision_layer = 1<<5
	break_time.stop()
	platform_ready = true
	#collider.set_deferred("set_collision_layer_value", 2, true)

func _on_break_time_timeout():
	destroy_platform()
	animation_player.speed_scale = 1

func _on_respawn_time_timeout():
	respawn_platform()


