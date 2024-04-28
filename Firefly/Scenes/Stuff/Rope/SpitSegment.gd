extends RigidBody2D
class_name SpitSegment
# :3

@onready var spit = $"."

var prev: RigidBody2D = null
var next: RigidBody2D = null

signal grabbed(segment)

# Connects the joint to the top of the spit
func connect_top(joint: PinJoint2D):
	joint.node_b = spit.get_path()


# Connects the give joint to the bottom of the spit
func connect_bottom(joint: PinJoint2D):
	joint.node_a = spit.get_path()


func connect_signal(function: Callable):
	
	var err = connect("grabbed", function)
	if err != OK:
		print("Stupid Error: ", err)

func player_grabbed():
	emit_signal("grabbed", self)
