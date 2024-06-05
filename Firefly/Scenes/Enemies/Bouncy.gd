extends Spring

@onready var walking_enemy = $".."
@onready var squish_node = $"../SquishNode"
@onready var collider: CollisionShape2D = $"../Collider"

## Returns true if we're blocking the spring
func block_spring():

	if not flyph.is_on_floor():
		return false

	if flyph.prev_velocity_y == 0:
		print("Blocked")
		return true

	return false

func spring_up_fx() -> void:
	
	
	sprite_2d.frame = 4
	# walking_enemy.call_deferred("set_collision_layer_value", 5, false)
	# walking_enemy.set_collision_layer_value()
	# collider.disabled = true
	squish_node.squish(Vector2(1.5,0.5))
	boing_.play(0)
	pass

func spring_down_fx() -> void:
	

	
	print("SPring Down Fx?")
	pass


