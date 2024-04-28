extends Node2D
class_name Worm

@onready var sprite_2d = $Sprite2D
@onready var point_light_2d = $PointLight2D

var first_segment: SpitSegment
var target_segment: SpitSegment
var target: Vector2
var active: bool = false
var reversed: bool = false
var climb_speed: float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _process(delta):
	
	if reversed:
		point_light_2d.position.y = -8
	else:
		point_light_2d.position.y = -4

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if active:
		crawl(delta)

	if round(global_position) == round(target):
		if not reversed:
			reached_segment()
		else:
			get_prev_segment()



func start_hunt(initial: SpitSegment, speed: float):
	
	first_segment = initial
	
	climb_speed = speed
	active = true
	target_segment = initial
	target = initial.get_node("Marker2D").global_position
	sprite_2d.play("Crawl")

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
		
		target_segment = target_segment.next
		reversed = false
		sprite_2d.flip_v = false
	else:	
		target_segment = target_segment.prev
		
	
	target = target_segment.get_node("Marker2D").global_position


var joint: DampedSpringJoint2D
func pin_worm_to_segment():
	# Creates
	pass
