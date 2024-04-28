extends Node2D


const SPIT = preload("res://Scenes/Stuff/Rope/spit.tscn")
const JOINT = preload("res://Scenes/Stuff/Rope/joint.tscn")
const ANCHOR = preload("res://Scenes/Stuff/Rope/anchor.tscn")
const WORM = preload("res://Scenes/Stuff/Rope/worm.tscn")

## Length of the rope
@export var Segments: int = 5
@export var Swingable: bool = true

@export_category("GlowWorm Properties")
@export var GlowWorm: bool = false
@export var worm_delay: float = 0.75
@export var worm_speed: float = 25


# Da base
@onready var base = $Base
@onready var lure = $PointLight2D


var worm_active: bool = false
var first_segment: SpitSegment = null

# Called when the node enters the scene tree for the first time.
func _ready():
	create_joints()
	if GlowWorm:
		setup_Worm()



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
		
		print(next_pos)
		
		add_child(joint)
		add_child(new_segment)
		
		# Connect the 'grabbed' signal to the 'activate' method
		new_segment.connect("grabbed", Callable(self, "activate"))
		
		
		print("bleh")
		
		
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
			
		
		prev_body = new_segment
		


func setup_Worm():
	lure.visible = true
	#pass
	
	
func activate(segment: SpitSegment):
	print("Segment activated:", segment.name)
	if GlowWorm:
		if not worm_active:
			
			var worm = WORM.instantiate()
			add_child(worm)
			# Wait 0.3 seconds before we can grab a rope again
			await get_tree().create_timer(worm_delay).timeout
			worm.start_hunt(first_segment, worm_speed)
			worm_active = true
	
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
