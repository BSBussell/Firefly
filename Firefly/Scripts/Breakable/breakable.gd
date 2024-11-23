extends Platform
class_name BreakablePlatform


@export_category("Properties")
@export var TIME_TO_BREAK: float = 1.0
@export var TIME_TO_RESPAWN: float = 3.0
@export var KILL_ON_EXIT: bool = true

@export_category("Don't Touch")
@export_subgroup("Nodes")
@export var collider: StaticBody2D
@export var sprite_2d: Sprite2D
@export var break_time: Timer
@export var respawn_time: Timer

@onready var explosion: CPUParticles2D = $Explosion
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var snap: AudioStreamPlayer2D = $Audio/Snap
@onready var crash: AudioStreamPlayer2D = $Audio/Crash
@onready var pop: AudioStreamPlayer2D = $Audio/Pop


var rng: RandomNumberGenerator
var platform_ready: bool = true

var plat_pitch: float = 1.0

# Called when the node enters the scene tree for the first time.
func child_ready():
	
	rng = RandomNumberGenerator.new()
	rng.seed = int(position.x + position.y)
	plat_pitch = rng.randf_range(0.75, 1.5)
	snap.pitch_scale = plat_pitch
	
	break_time.wait_time = TIME_TO_BREAK
	respawn_time.wait_time = TIME_TO_RESPAWN
	
	var err = connect("player_landed", Callable(self, "_on_player_landed"))
	if err != OK:
		print(self.name)
	
	connect("player_left", Callable(self, "_on_player_left"))
	
	
func _on_player_landed(_player):
	if TIME_TO_BREAK != -1:
		
		snap.play()
		
		if break_time.is_stopped():
			break_time.start()
			
		# Reset the animation to the default values
		animation_player.play("RESET")
		animation_player.play("Shake")
		animation_player.speed_scale = 2


func _on_player_left(_player):
	if KILL_ON_EXIT and not break_time.is_stopped():
		break_time.stop()
		destroy_platform()


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
	if TIME_TO_BREAK != -1:
		destroy_platform()
	

func _on_respawn_time_timeout():
	if TIME_TO_RESPAWN != -1:
		respawn_platform()







