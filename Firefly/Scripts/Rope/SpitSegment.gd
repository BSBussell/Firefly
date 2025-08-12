extends RigidBody2D
class_name SpitSegment
# :3

@export var spotlight: PointLight2D = null
@export var path_point: PathFollow2D

@onready var spit = $"."

@onready var sprite_2d = $Sprite2D
@onready var sprite_2d_2 = $Sprite2D2


var root: Rope = null

# Hooked up by rope
var prev: RigidBody2D = null
var next: RigidBody2D = null


var origin: Vector2 = Vector2.ZERO


signal grabbed(segment)


var is_decor: bool = false

func _ready():
	if is_decor:
		dim()
# Connects the joint to the top of the spit
func connect_top(joint: PinJoint2D):
	joint.node_b = spit.get_path()


# Connects the give joint to the bottom of the spit
func connect_bottom(joint: PinJoint2D):
	joint.node_a = spit.get_path()


func connect_signal(function: Callable):
	
	var err = connect("grabbed", function)
	if err != OK:
		print("Error connecting signal: ", err)

func player_grabbed():
	_logger.info("Segment - Emitting Grabbed Signal")
	emit_signal("grabbed", self)
	path_point.progress_ratio = 0.5 

func start_cooldown(time: float) -> void:
	root.start_cooldown(time)

func set_decor() -> void:
	is_decor = true

func dim() -> void:
	if spotlight:
		
		spotlight.enabled = false
		spotlight.queue_free()  
		
	
	# Make the material unique to this node
	sprite_2d.material = sprite_2d.material.duplicate()

	# Now change the shader param
	sprite_2d.material.set_shader_parameter("albedo_tint", Vector4(0.111, 0.2, 0.35, 1))
	
	sprite_2d_2.material = sprite_2d.material.duplicate()

	# Now change the shader param
	sprite_2d_2.material.set_shader_parameter("albedo_tint", Vector4(0.111, 0.2, 0.35, 1))
	
