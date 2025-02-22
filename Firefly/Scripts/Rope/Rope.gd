extends Node2D
class_name Rope

## Length of the rope
@export var Segments: int = 5
@export var Swingable: bool = true
@export var disabled_tint: Color = Color("#3e3b65bf")

@export_category("GlowWorm Properties")
## Does this rope have a glow worm?
@export var GlowWorm: bool = false
## How long does the worm wait after a player grabs the rope?
@export var worm_delay: float = 0.75
## How fast does the worm move?
@export var worm_speed: float = 25

@export_category("Rope Varient")
@export var SPIT: PackedScene = preload("res://Scenes/Stuff/Rope/RopePieces/spit.tscn")
@export var JOINT: PackedScene = preload("res://Scenes/Stuff/Rope/RopePieces/joint.tscn")
@export var ANCHOR: PackedScene = preload("res://Scenes/Stuff/Rope/RopePieces/anchor.tscn")
@export var WORM: PackedScene = preload("res://Scenes/Stuff/Rope/GlowWorm/worm.tscn")

# Da base
@onready var base = $Base
@onready var lure = $PointLight2D


var active_worm: Worm = null
var worm_active: bool = false
var first_segment: SpitSegment = null
var segments: Array = []

# Called when the node enters the scene tree for the first time.
func _ready():

	_logger.info("Rope - Ready")

	create_joints()
	if GlowWorm:
		setup_Worm()
		
	if not Swingable:
		self_modulate = "#3e3b65bf"

	_logger.info("Rope - Ready Finished")



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
			new_segment.set_deferred("collision_layer", 0)
			new_segment.set_deferred("collision_mask", 0)
			new_segment.modulate = disabled_tint
			new_segment.set_decor()
			
		
		
		new_segment.origin = global_position
		new_segment.root = self
		
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
	
	_logger.info("Rope - Cooldown Function Started")
	
	for each: SpitSegment in segments:
		each.set_deferred("collision_layer", 0)
		
	_logger.info("Rope - Cooldown Started")
	
	await get_tree().create_timer(time).timeout
	
	_logger.info("Rope - Cooldown Finished")


	for each: SpitSegment in segments:
		each.set_deferred("collision_layer", 1 << 8)
	
	_logger.info("Rope - Cooldown Finished")
		
	
