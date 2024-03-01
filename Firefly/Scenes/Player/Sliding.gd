
extends PlayerState

@export_subgroup("TRANSITIONAL STATES")
@export var GROUNDED_STATE: PlayerState = null
@export var AERIAL_STATE: PlayerState = null

# And check the jump buffer on landing
@export_subgroup("Input Assists")
@export var jump_buffer: Timer
@export var coyote_time: Timer


@onready var landing_dust = $"../../Particles/LandingDustSpawner"
@onready var sliding_sfx = $"../../Audio/SlidingSFX"
@onready var landing_sfx = $"../../Audio/LandingSFX"
@onready var slide_dust = $"../../Particles/SlideDust"



var entryVel: float

var slidingDown = false

# Called on state entrance, setup
func enter() -> void:
	
	print("Sliding State")
	
	slidingDown = false
	
	# Give dust on landing
	if (parent.current_animation == parent.ANI_STATES.FALLING):
		var new_cloud = parent.LANDING_DUST.instantiate()
		new_cloud.set_name("landing_dust_temp")
		landing_dust.add_child(new_cloud)
		var animation = new_cloud.get_node("AnimationPlayer")
		animation.play("free")
		
		landing_sfx.play(0)
	
	# Crawl Animation
	parent.current_animation = parent.ANI_STATES.CRAWL
	
	
	parent.floor_constant_speed = false
	
	if abs(parent.velocity.x) > 0:
		slide_dust.emitting = true
		slide_dust.direction.x *= 1 if (parent.velocity.x > 0) else -1
		sliding_sfx.play(0)	
	
	
	entryVel = parent.velocity.x
		
	parent.wallJumping = false
	
	pass

# Called before exiting the state, cleanup
func exit() -> void:
	
	sliding_sfx.stop()
	
	if abs(parent.velocity.x) > abs(entryVel) or abs(parent.velocity.x) > parent.speed:
		parent.update_slides(1)
		print("Optimal Slide :3")
	else:
		parent.update_slides(0)
		#print("Optimal Slide Usage :3")
	
	parent.floor_constant_speed = true
	slide_dust.emitting = false
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
	
	# Stop it when we stop moving
	if parent.velocity.x == 0:
		sliding_sfx.stop()
		slide_dust.emitting = false
	else:
		sliding_sfx.stop()
		slide_dust.emitting = true
		slide_dust.direction.x *= 1 if (parent.velocity.x > 0) else -1
	
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
		
		# My favorite implication of this, is that it won't immediately clamp the players velocity
		# To the min, so if the player has a faster air speed than ground speed, then they can 
		# Crouch for just a second before jumping again to retain that speed...
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
		
		
