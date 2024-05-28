extends Node2D

@export_category("Properties")
@export var TIME_TO_BREAK: float = 1.0
@export var TIME_TO_RESPAWN: float = 3.0
@export var KILL_ON_EXIT: bool = true

@export_category("Don't Touch")
@export_subgroup("Nodes")
@export var sprite_2d: Sprite2D
@export var break_time: Timer
@export var respawn_time: Timer
@export var collider: StaticBody2D

@onready var explosion: CPUParticles2D = $Explosion
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var snap: AudioStreamPlayer2D = $Audio/Snap
@onready var crash: AudioStreamPlayer2D = $Audio/Crash
@onready var pop: AudioStreamPlayer2D = $Audio/Pop


## Player
var flyph: Flyph = null

var rng: RandomNumberGenerator
var platform_ready: bool = true

var plat_pitch: float = 1.0

# Called when the node enters the scene tree for the first time.
func _ready():
	
	rng = RandomNumberGenerator.new()
	rng.seed = position.x + position.y
	plat_pitch = rng.randf_range(0.75, 1.5)
	snap.pitch_scale = plat_pitch
	
	break_time.wait_time = TIME_TO_BREAK
	break_time.wait_time = TIME_TO_RESPAWN
	
	
	pass


func _physics_process(delta):
	
	if flyph and flyph.is_on_floor():
		
		
		snap.play()
		
		if break_time.is_stopped():
			break_time.start()
			
		# Reset the animation to the default values
		animation_player.play("RESET")
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
	
	if KILL_ON_EXIT and not break_time.is_stopped():
		break_time.stop()
		destroy_platform()
	
	if flyph:
		set_physics_process(false)
		flyph = null

func destroy_platform():
	
	animation_player.speed_scale = 1
	animation_player.play("Break")
	collider.collision_layer = 0
	crash.play()
	respawn_time.start()
	platform_ready = false
	

func respawn_platform():
	
	pop.play()
	animation_player.play("respawn")
	collider.collision_layer = 1<<5
	break_time.stop()
	platform_ready = true

func _on_break_time_timeout():
	destroy_platform()
	

func _on_respawn_time_timeout():
	respawn_platform()


