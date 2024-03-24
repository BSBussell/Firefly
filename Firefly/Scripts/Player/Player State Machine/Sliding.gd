
extends PlayerState

@export_subgroup("TRANSITIONAL STATES")
@export var GROUNDED_STATE: PlayerState = null
@export var AERIAL_STATE: PlayerState = null

# And check the jump buffer on landing
@export_subgroup("Input Assists")
@export var jump_buffer: Timer
@export var coyote_time: Timer

# Particle Effects
@onready var landing_dust = $"../../Particles/LandingDustSpawner"
@onready var slide_dust = $"../../Particles/SlideDust"
@onready var speed_particles = $"../../Particles/MegaSpeedParticles"

# Sound Effects
@onready var sliding_sfx = $"../../Audio/SlidingSFX"
@onready var landing_sfx = $"../../Audio/LandingSFX"

@onready var crouch_jumping_sfx = $"../../Audio/CrouchJumpingSFX"

@onready var crouch_jump_window = $"../../Timers/CrouchJumpWindow"
@onready var crouch_jump_disable = $"../../Timers/CrouchJumpDisable"

var entryVel: float

var slidingDown = false
var jumpExit = false


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
	
		parent.animation.scale = Vector2( 1.1, 0.9)
	
		# Crouch Animation
		parent.current_animation = parent.ANI_STATES.LANDING
	
	# This might be silly b/c i can't control it lol
	parent.floor_constant_speed = false
	
	if abs(parent.velocity.x) > 0:
		slide_dust.emitting = true
		slide_dust.direction.x *= 1 if (parent.velocity.x > 0) else -1
		sliding_sfx.play(0)
		
	entryVel = parent.velocity.x
		
	jumpExit = false
	parent.set_crouch_collider()
	
	crouch_jump_window.start()
	
	pass

# Called before exiting the state, cleanup
func exit() -> void:
	
	sliding_sfx.stop()
	
	slide_dust.emitting = false
	
	if not jumpExit:
		coyote_time.start()
	
	# This might be silly b/c i can't control it lol
	parent.floor_constant_speed = true
	
	pass

# Processing input in this state, returns nil or new state
func process_input(_event: InputEvent) -> PlayerState:
	
	
	return null

# Processing Frames in this state, returns nil or new state
func process_frame(_delta: float) -> PlayerState:
	
	if abs(parent.velocity.x) > parent.speed:
		speed_particles.emitting = true
		speed_particles.direction.x = 1 if (parent.animation.flip_h) else -1
	else:
		speed_particles.emitting = false
	return null

# Processing Physics in this state, returns nil or new state
func process_physics(delta: float) -> PlayerState:
	
	
		
	
	
	# Just need to be able to jump and apply friction tbh
	jump_logic(delta)
	apply_friction(delta, parent.horizontal_axis)
	
	update_state(parent.horizontal_axis)
	
	# Make Sure we're still grounded after this
	if not parent.is_on_floor():
		# Reset Animation State in case of change
		parent.current_animation = parent.ANI_STATES.CRAWL
		return AERIAL_STATE
		
	# Stay there til we let go of down
	if not Input.is_action_pressed("Down") and AERIAL_STATE.have_stand_room():
		parent.current_animation = parent.ANI_STATES.STANDING_UP
		
		parent.animation.scale = Vector2(0.9, 1.1)
		return GROUNDED_STATE
	#parent.move_and_slide()
	
	
		
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
	
	# Sliding Downhill
	else:
		
		var sign = sign(parent.get_floor_normal().x)
		parent.animation.flip_h = sign <= 0 # Flip the sprite based on slide dir
		
		var speed = sign * parent.hill_speed
		var accel = parent.hill_accel
		
		parent.velocity.x = move_toward(parent.velocity.x, speed, accel*delta)
		
		

# TODO: Add jump lag in order to show the crouch animation
func jump_logic(_delta):
	
	if Input.is_action_just_pressed("Jump") or GROUNDED_STATE.jump_buffer.time_left > 0.0: 
		
		# Prevent silly interactions between jumping and wall jumping
		GROUNDED_STATE.jump_buffer.stop()
		#jump_buffer.wait_time = -1
		
		#GROUNDED_STATE.jumping_sfx.play(0)
		
		
		
		# If we aren't crouch jumping just do a normal jump
		if not crouch_jump():
			
			# Velocity y
			parent.velocity.y = (parent.jump_velocity * 0.8)
			
			# Normal Jump Dust
			var new_cloud = parent.JUMP_DUST.instantiate()
			new_cloud.set_name("jump_dust_temp")
			GROUNDED_STATE.jump_dust.add_child(new_cloud)
			var animation = new_cloud.get_node("AnimationPlayer")
			animation.play("free")
			
			# Normal Jump SFX
			GROUNDED_STATE.jumping_sfx.play(0)
			parent.crouchJumping = true
		
			parent.animation.scale = Vector2(0.8, 1.2)
		
		# TODO: Rename this or relook at it
		
		jumpExit = true

# Updates animation states based on changes in physics
func update_state(direction):
	
	# Change direction
	if direction > 0 and parent.animation.flip_h:
		parent.animation.flip_h = false
		parent.animation.scale = Vector2(0.6, 1.0)
		
	elif direction < 0 and not parent.animation.flip_h:
		parent.animation.flip_h = true
		parent.animation.scale = Vector2(0.6, 1)

	# Stop sfx when we stop moving
	if parent.velocity.x == 0:
		sliding_sfx.stop()
		slide_dust.emitting = false
	else:
		sliding_sfx.play(sliding_sfx.get_playback_position())
		slide_dust.emitting = true
		slide_dust.direction.x *= 1 if (parent.velocity.x > 0) else -1


# This is a big messy, but essentially crouch jump returns true if we perform
# A crouch jump and false if we don't
func crouch_jump() -> bool:
	
	# throw in this to make it slightly less free
	if (crouch_jump_window.time_left == 0 ) and abs(parent.velocity.x) > abs(parent.speed) * parent.movement_data.CROUCH_JUMP_THRES: #and parent.canCrouchJump:
		
		parent.velocity.y = parent.jump_velocity * parent.movement_data.CROUCH_JUMP_HEIGHT_MULTI
		
		# If velocity is moving in the same direction as our direction
		# Add onto speed
		if parent.velocity.x * parent.horizontal_axis > 0:
			
			parent.velocity.x += parent.movement_data.CROUCH_JUMP_BOOST * parent.horizontal_axis
		
		# Otherwise instant reset :3
		else:
			
			# Flip velocity (or zero it)
			parent.velocity.x *= -parent.movement_data.CJ_REVERSE_MULTIPLIER
			# Then add to it
			parent.velocity.x += parent.movement_data.CROUCH_JUMP_BOOST * parent.horizontal_axis
			
			
		# Spawn Dust effects
		var new_cloud = parent.CROUCH_JUMP_DUST.instantiate()
		new_cloud.direction.x *= sign(parent.horizontal_axis)
		new_cloud.gravity.x *= sign(parent.horizontal_axis)
		new_cloud.set_name("crouch_jump_dust_temp")
		GROUNDED_STATE.jump_dust.add_child(new_cloud)
		var animation = new_cloud.get_node("AnimationPlayer")
		animation.play("free")
		
		# Play crouch jump sfx
		crouch_jumping_sfx.play(0)
		
		# Squash the sprite
		parent.animation.scale = Vector2(0.7, 1.1)
		
		# Set crouch jumpint to true
		parent.crouchJumping = true
		
		
		return true
	
	return false
	

