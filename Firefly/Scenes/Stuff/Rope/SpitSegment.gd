extends RigidBody2D
class_name SpitSegment
# :3

@onready var spit = $"."


# Connects the joint to the top of the spit
func connect_top(joint: PinJoint2D):
	joint.node_b = spit.get_path()


# Connects the give joint to the bottom of the spit
func connect_bottom(joint: PinJoint2D):
	joint.node_a = spit.get_path()




