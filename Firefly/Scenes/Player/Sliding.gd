
extends PlayerState

@export_subgroup("TRANSITIONAL STATES")
@export var GROUNDED_STATE: PlayerState = null
@export var AERIAL_STATE: PlayerState = null

# And check the jump buffer on landing
@export_subgroup("Input Assists")
@export var jump_buffer: Timer
@export var coyote_time: Timer


@onready var landing_dust = $"../../Particles/LandingDustSpawner"

var slidingDown = false

# Called on state entrance, setup
func enter() -> void:
	
	print("Sliding State")
	
	slidingDown = false
	
	# Crawl Animation
	parent.current_animation = parent.ANI_STATES.CRAWL
	
	
	parent.floor_constant_speed = false
	
	# Give dust on landing
	var new_cloud = parent.LANDING_DUST.instantiate()
	new_cloud.set_name("landing_dust_temp")
	landing_dust.add_child(new_cloud)
	var animation = new_cloud.get_node("AnimationPlayer")
	animation.play("free")
		
	parent.wallJumping = false
	
	pass

# Called before exiting the state, cleanup
func exit() -> void:
	
	
	parent.floor_constant_speed = true
	pass

# Processing input in this state, returns nil or new state
func process_input(_event: InputEvent) -> PlayerState:
	
	# Stay there til we let go of down
	if not Input.is_action_pressed("Down"):
		parent.current_animation = parent.ANI_STATES.STANDING_UP
		return GROUNDED_STATE
	return null

# Processing Frames in this state, returns nil or new state
func process_frame(_delta: float) -> PlayerState:
	return null

# Processing Physics in this state, returns nil or new state
func process_physics(delta: float) -> PlayerState:
	
	GROUNDED_STATE.jump_logic(delta)
	
	apply_friction(delta, parent.horizontal_axis)
	
	
	parent.move_and_slide()
	
	GROUNDED_STATE.update_state(parent.horizontal_axis)
	
	# Make Sure we're still grounded after this
	if not parent.is_on_floor():
		return AERIAL_STATE
		
	return null
	
func animation_end() -> PlayerState:
	
	
	return null


func apply_friction(delta, direction):
	
	parent.turningAround = false	
	
	
	# IF LEVEL GROUND
	if parent.get_floor_normal() == Vector2.UP:
		var friction = parent.slide_friction
		parent.velocity.x = move_toward(parent.velocity.x, 0, friction * delta)
		slidingDown = false
	
	else:
		var sign
		if parent.get_floor_normal().x > 0:
			sign = 1
			parent.animation.flip_h = false
		else:
			sign = -1	
			parent.animation.flip_h = true
		
		
		var speed = sign * parent.hill_speed
		var accel = parent.hill_accel
		
		parent.velocity.x = move_toward(parent.velocity.x, speed, accel*delta)
		
		
