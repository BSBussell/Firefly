extends Node2D
class_name Worm

@onready var sprite_2d = $Sprite2D
@onready var point_light_2d = $PointLight2D
@onready var audio_stream_player_2d = $AudioStreamPlayer2D

@onready var timer = $Timer

var first_segment: SpitSegment
var target_segment: SpitSegment
var target: Vector2
var active: bool = false
var reversed: bool = false
var climb_speed: float = 0.0
var delay: float = 1.0

# Called when the node enters the scene tree for the first time.
func _ready():
	
	timer.start(delay)
	

func _process(delta):
	
	_logger.info("Worm - Process Start")

	if reversed:
		point_light_2d.position.y = -8
	else:
		point_light_2d.position.y = -4

	_logger.info("Worm - Process End")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):

	_logger.info("Worm - Physics Process Start")

	if active:
		crawl(delta)

	if round(global_position) == round(target):
		if not reversed:
			reached_segment()
		else:
			get_prev_segment()

	_logger.info("Worm - Physics Process End")

func setup_hunt(initial: SpitSegment, speed: float, delay: float):
	
	first_segment = initial
	climb_speed = speed
	target_segment = initial
	self.delay = delay
	

func start_hunt():
	
	active = true
	target = target_segment.get_node("Marker2D").global_position
	sprite_2d.play("Crawl")
	audio_stream_player_2d.play()

func crawl(delta):
	
	
	target = target_segment.get_node("Marker2D").global_position
	#global_position = target
	global_position.x = move_toward(global_position.x, target.x, delta * 500)
	global_position.y = move_toward(global_position.y, target.y, delta * climb_speed)
	rotation = (target_segment.rotation)
	
	
func reached_segment():
	
	if target_segment.next == null:
		
		target_segment = target_segment.prev
		reversed = true
		sprite_2d.flip_v = true
	else:	
		target_segment = target_segment.next
		
	
	target = target_segment.get_node("Marker2D").global_position


func get_prev_segment():
	if target_segment.prev == null:
		
		target_segment.root.kill_worm()
	else:	
		target_segment = target_segment.prev
		
	
	target = target_segment.get_node("Marker2D").global_position


func _on_audio_stream_player_2d_finished():
	audio_stream_player_2d.play()


func _on_timer_timeout():
	start_hunt()
