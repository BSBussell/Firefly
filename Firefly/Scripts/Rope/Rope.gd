extends Node2D
class_name Rope

const SPIT = preload("res://Scenes/Stuff/Rope/RopePieces/spit.tscn")
const JOINT = preload("res://Scenes/Stuff/Rope/RopePieces/joint.tscn")
const ANCHOR = preload("res://Scenes/Stuff/Rope/RopePieces/anchor.tscn")
const WORM = preload("res://Scenes/Stuff/Rope/GlowWorm/worm.tscn")

## Length of the rope
@export var Segments: int = 5
@export var Swingable: bool = true

@export_category("GlowWorm Properties")
## Does this rope have a glow worm?
@export var GlowWorm: bool = false
## How long does the worm wait after a player grabs the rope?
@export var worm_delay: float = 0.75
## How fast does the worm move?
@export var worm_speed: float = 25


# Da base
@onready var base = $Base
@onready var lure = $PointLight2D


var active_worm: Worm = null
var worm_active: bool = false
var first_segment: SpitSegment = null
var segments: Array = []

# Called when the node enters the scene tree for the first time.
func _ready():
	create_joints()
	if GlowWorm:
		setup_Worm()
		
	if not Swingable:
		self_modulate = "#3e3b65bf"



func create_joints() -> void:
	
	var prev_body: PhysicsBody2D = base
	var next_pos: Vector2 = Vector2.ZERO
	
	for i in range(Segments):
		
		var new_segment: SpitSegment
		var joint: PinJoint2D
		
		if i == Segments - 1:
			new_segment = ANCHOR.instantiate()
			
			joint = JOINT.instantiate()

			new_segment.position = next_pos
			joint.position = next_pos
			
			
		else:
			new_segment = SPIT.instantiate()
			
			joint = JOINT.instantiate()

			new_segment.position = next_pos
			joint.position = next_pos
			
			## ONLY DIFF about anchor
			next_pos += new_segment.get_node("Marker2D").position
			
			
		if not Swingable:
			new_segment.set_collision_layer_value(9, false)
			new_segment.set_collision_mask_value(1, true)
			new_segment.modulate = "#3e3b65bf"
		
		
		new_segment.origin = global_position
		
		add_child(joint)
		add_child(new_segment)
		
		# Connect the 'grabbed' signal to the 'activate' method
		new_segment.connect("grabbed", Callable(self, "activate"))
		
		var spitSeg = prev_body as SpitSegment
		
		if spitSeg:
			
			spitSeg.connect_bottom(joint)
			new_segment.connect_top(joint)
			
			spitSeg.next = new_segment
			new_segment.prev = spitSeg
			
		# If we're the base 
		else:
			
			joint.node_a = prev_body.get_path()
			new_segment.connect_top(joint)
			
			first_segment = new_segment
			new_segment.prev = null
			
		
		segments.append(new_segment)
		prev_body = new_segment
		


func setup_Worm():
	lure.visible = true
	#pass
	
	
func activate(_segment: SpitSegment):
	
	_logger.info("Rope - Receiving Grabbed Signal")
	
	if GlowWorm:
		if not worm_active:
			
			worm_active = true
			active_worm = WORM.instantiate()
			#add_child(active_worm)
			
			call_deferred("add_child", active_worm)
			
			# Wait X amount seconds before we can grab a rope again
			active_worm.setup_hunt(first_segment, worm_speed, worm_delay)
			

func kill_worm():
	
	if worm_active:
		active_worm.queue_free()
		worm_active = false	
	
func start_cooldown(time: float) -> void:
	
	for each: SpitSegment in segments:
		each.set_deferred("collision_layer", 0)
		#each.set_collision_layer_value(9, false)
		
	await get_tree().create_timer(time).timeout
	
	for each: SpitSegment in segments:
		each.set_deferred("collision_layer", 256)
		#each.set_collision_layer_value(9, true)
	
