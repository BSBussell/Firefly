extends Node2D


const SPIT = preload("res://Scenes/Stuff/Rope/spit.tscn")
const JOINT = preload("res://Scenes/Stuff/Rope/joint.tscn")
const ANCHOR = preload("res://Scenes/Stuff/Rope/anchor.tscn")

## Length of the rope
@export var Segments: int = 5
@export var Swingable: bool = true
@export var GlowWorm: bool = false


# Da base
@onready var base = $Base
@onready var lure = $PointLight2D

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
		print("bleh")
		
		
		var spitSeg = prev_body as SpitSegment
		
		if spitSeg:
			
			spitSeg.connect_bottom(joint)
			new_segment.connect_top(joint)
			
		# Simply Attach the 
		else:
			joint.node_a = prev_body.get_path()
			new_segment.connect_top(joint)
			#joint.node_b = new_segment.get_path()
		
		prev_body = new_segment
		


func setup_Worm():
	lure.visible = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
