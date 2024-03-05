
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
@onready var collider_rect = $"../../Collider_rect"

@onready var standing_collider = $"../../Standing_Collider"
@onready var crouching_collider = $"../../Crouching_Collider"

@onready var stand_room = $"../../Raycasts/Colliders/Stand_Room"


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
	
		# Crouch Animation
		parent.current_animation = parent.ANI_STATES.LANDING
	
	
	parent.floor_constant_speed = false
	
	if abs(parent.velocity.x) > 0:
		slide_dust.emitting = true
		slide_dust.direction.x *= 1 if (parent.velocity.x > 0) else -1
		sliding_sfx.play(0)
	
	# 
	standing_collider.disabled = true
	crouching_collider.disabled = false
	
	entryVel = parent.velocity.x
		
	parent.set_crouch_collider()
	
	pass

# Called before exiting the state, cleanup
func exit() -> void:
	
	sliding_sfx.stop()
	
	if abs(parent.velocity.x) > abs(entryVel) or abs(parent.velocity.x) > parent.speed:
		parent.update_slides(1)
	else:
		parent.update_slides(0)
	
	slide_dust.emitting = false
	
	pass

# Processing input in this state, returns nil or new state
func process_input(_event: InputEvent) -> PlayerState:
	
	
	return null

# Processing Frames in this state, returns nil or new state
func process_frame(_delta: float) -> PlayerState:
	return null

# Processing Physics in this state, returns nil or new state
func process_physics(delta: float) -> PlayerState:
	
	jump_logic(delta)
	apply_friction(delta, parent.horizontal_axis)
	
	parent.move_and_slide()
	
	# Stop it when we stop moving
	if parent.velocity.x == 0:
		sliding_sfx.stop()
		slide_dust.emitting = false
	else:
		sliding_sfx.play(sliding_sfx.get_playback_position())
		slide_dust.emitting = true
		slide_dust.direction.x *= 1 if (parent.velocity.x > 0) else -1
		
	
	update_state(parent.horizontal_axis)
	
	# Make Sure we're still grounded after this
	if not parent.is_on_floor():
		# Reset Animation State in case of change
		parent.current_animation = parent.ANI_STATES.CRAWL
		return AERIAL_STATE
		
	# Stay there til we let go of down
	if not Input.is_action_pressed("Down") and  not stand_room.is_colliding():
		parent.current_animation = parent.ANI_STATES.STANDING_UP
		return GROUNDED_STATE
		
	return null
	
func animation_end() -> PlayerState:
	
	# If we are landing go to crouch
	if parent.current_animation == parent.ANI_STATES.LANDING:
		parent.current_animation = parent.ANI_STATES.CROUCH
	
	# If we are crouching go to crawl
	if parent.current_animation == parent.ANI_STATES.CROUCH:
		parent.current_animation = parent.ANI_STATES.CRAWL
	
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
		
		

# TODO: Add jump lag in order to show the crouch animation
func jump_logic(_delta):
	
	if Input.is_action_just_pressed("Jump") or GROUNDED_STATE.jump_buffer.time_left > 0.0: 
		
		
		var new_cloud = parent.JUMP_DUST.instantiate()
		new_cloud.set_name("jump_dust_temp")
		GROUNDED_STATE.jump_dust.add_child(new_cloud)
		var animation = new_cloud.get_node("AnimationPlayer")
		animation.play("free")
		
		
		# Prevent silly interactions between jumping and wall jumping
		GROUNDED_STATE.jump_buffer.stop()
		#jump_buffer.wait_time = -1
		
		GROUNDED_STATE.jumping_sfx.play(0)
		
		parent.velocity.y = parent.jump_velocity
		
		parent.crouchJumping = true

# Updates animation states based on changes in physics
func update_state(direction):
	
	# Change direction (cANT DO SLIDING
	if direction > 0:
		parent.animation.flip_h = false
		#dust.gravity.x = -200
	elif direction < 0:
		parent.animation.flip_h = true
		#dust.gravity.x *= 200
