extends PlayerState

@export_subgroup("DEPENDENT STATES")
@export var AERIAL_STATE: PlayerState = null

@export_category("Climb Values")
@export var up_max_speed: float = 0.025
@export var down_max_speed: float = -0.075

@export var up_accel: float = 0.02
@export var down_accel: float = 0.05

@export var up_climb_friction: float = 0.021
@export var down_climb_friction: float = 0.04

@export_category("Swing Values")
@export var swing_force: float = 400
@export var max_swing_force: float = 2000
@export var min_swing_force: float = 600
@export var swing_down_accel: float = 1200
@export var swing_up_decel: float = 800
@export var player_weight: float = 980

@export var grab_force_multi: float = 1.75
@export var jump_force_multi: float = -1.75

# The player should be able to do a lot regardless
# with swinging
## The base multiplier when jumping off a rope
@export var swing_min: float = 3.5
## The max multiplier when jumping off a rope at the right timing.
@export var max_jump_multi: float = 8

## Height of jumping off a rope
@export var swing_jump_height: float = 2.0
@export var swing_jump_rise_time: float = 0.2
@export var boosted_sj_height: float = 2.0
@export var boost_sj_rise_time: float = 0.3


# Effects
@onready var speed_particles = $"../../Particles/SpeedParticles"
@onready var jump_dust = $"../../Particles/JumpDustSpawner"
@onready var jumping_sfx = $"../../Audio/JumpingSFX"

# Rope Detector
@onready var rope_detector = $"../../Physics/RopeDetector"

@onready var rope_tighten_sfx = $"../../Audio/RopeTightenSFX"
@onready var rope_creak_sfx = $"../../Audio/RopeCreakSFX"


@onready var real_swing_jump_height: float = swing_jump_height * 16
@onready var real_bsj_height: float = boosted_sj_height * 16

## The vertical velocity of the player when they swing jump
@onready var swing_jump_velocity: float = ((-2.0 * real_swing_jump_height) / swing_jump_rise_time)
## The gravity of the player when they swing jump
@onready var swing_jump_gravity: float = ((-2.0 * real_swing_jump_height) / pow(swing_jump_rise_time, 2))

## The vertical velocity of the player when they boost jump
@onready var boost_sj_velocity: float = ((-2.0 * real_bsj_height) / boost_sj_rise_time)
## The gravity of the player when they boost jump
@onready var boost_sj_gravity: float = ((-2.0 * real_bsj_height) / pow(boost_sj_rise_time, 2))

# Called on state entrance, setup
func enter() -> void:
	
	
	
	if OS.is_debug_build():
		_logger.info("Wormed State")

	# We are not speeding up on thingy
	speeding_up = false

	parent.set_standing_collider()

	# Make us unable to grab another rope
	rope_detector.set_deferred("monitoring", false)
	
	climb_speed = 0.0
	
	var speed_ratio = min(abs(parent.velocity.x) / (parent.air_speed * 2.5), 1.0)
	swing_force = snappedf(lerpf(min_swing_force, max_swing_force, speed_ratio), 1)
	
	
	# Relative position to the ropes center
	var a = lerpf(min_frequency, max_frequency, swing_force/max_swing_force)
	# This is the coolest shit i've done
	if sign(parent.velocity.x) > 0:
		period = PI/(2*a) 
	else:
		period = (3*PI)/(2*a)
			
	pendulum_force = swing_force
	

	apply_rope_impulse(parent.velocity * grab_force_multi)

	
	rand_from_seed(int(parent.stuck_segment.root.global_position.x))
	rope_creak_sfx.pitch_scale = randf_range(1, 2)
	rope_creak_sfx.play()
	
	
	rope_tighten_sfx.pitch_scale = randf_range(1, 2)
	rope_tighten_sfx.play()

	
	# Put us in the falling animation if we are not crouch jumping, jumping, or if we're launched
	parent.current_animation = parent.ANI_STATES.WALL_SLIDE
	parent.restart_animation = true
		
	_logger.info("We have finished Enter")


	


# Called before exiting the state, cleanup
func exit() -> void:

	
	# And any potentially on particles
	speed_particles.emitting = false

	parent.stuck_segment.start_cooldown(0.2)
	parent.stuck_segment = null
	
	 #Wait 0.3 seconds before we can grab a rope again
	#await get_tree().create_timer(0.2).timeout
	
	rope_detector.set_deferred("monitoring", true)
	#rope_detector.set_collision_mask_value(9, true)
	
	
	rope_creak_sfx.stop()

	_logger.info("Flyph - Worm Exit")

	


# Processing input in this state, returns nil or new state
func process_input(event: InputEvent) -> PlayerState:

	_logger.info("Processing Input")

	return null

	# If its just a keyboard
	if event is InputEventKey:
		if Input.is_action_just_pressed("Down"):
			
			parent.stuck_segment.path_point.progress_ratio -= 0.1
			if parent.stuck_segment.path_point.progress_ratio <= 0.1:
				if parent.stuck_segment.next:
					parent.stuck_segment = parent.stuck_segment.next
					parent.stuck_segment.path_point.progress_ratio = 1.0
				else:
					return AERIAL_STATE
				
		elif Input.is_action_just_pressed("Up"):
			
			parent.stuck_segment.path_point.progress_ratio += 0.1
			if parent.stuck_segment.path_point.progress_ratio >= 0.9:
				if parent.stuck_segment.prev:
					parent.stuck_segment = parent.stuck_segment.prev
					parent.stuck_segment.path_point.progress_ratio = 0.0
	
	# If its anything other than a keyboard
	else:
		if Input.is_action_just_pressed("Down") and not Input.is_action_just_pressed("Dive"):
			if parent.stuck_segment.next:
				parent.stuck_segment = parent.stuck_segment.next
			else:
				return AERIAL_STATE

		elif Input.is_action_just_pressed("Up"):
			if parent.stuck_segment.prev:
				parent.stuck_segment = parent.stuck_segment.prev



	return null

# Processing Physics in this state, returns nil or new state
func process_physics(delta: float) -> PlayerState:

	_logger.info("Wormed Process Physics")

	if climb_rope(delta, parent.vertical_axis):
		return AERIAL_STATE

	# Swing
	swinging(delta, parent.horizontal_axis)
	
	apply_weight(delta)
	
	velocity_decay(delta)
	
	

	# Water State Change Handled by the Water Detection
	if handle_jump(delta):

		_logger.info("Finished Wormed Process Physics - Jumping")

		return AERIAL_STATE
		
	_logger.info("Finished Wormed Process Physics")

	return null




func process_frame(_delta):

	_logger.info("Wormed Process Frame")

	# Direction Facing, don't update if we're walljumping up
	if not (parent.wallJumping and parent.current_wj == parent.WALLJUMPS.UPWARD):
		if parent.horizontal_axis < 0 and not parent.animation.flip_h:
			
			rope_creak_sfx.play(rope_creak_sfx.get_playback_position())
			
			
			parent.animation.flip_h = true
			parent.squish_node.squish(parent.turn_around_squash)

		elif parent.horizontal_axis > 0 and parent.animation.flip_h:
			
			
			rope_creak_sfx.play(rope_creak_sfx.get_playback_position())
			
			parent.animation.flip_h = false
			parent.squish_node.squish(parent.turn_around_squash)

	# Speed Particle Emission
	if abs(parent.velocity.x) > parent.air_speed + parent.movement_data.JUMP_HORIZ_BOOST or parent.temp_gravity_active or speeding_up:
		speed_particles.emitting = true
		speed_particles.direction.x = 1 if (parent.animation.flip_h) else -1
	else:
		speed_particles.emitting = false

	if parent.horizontal_axis:
		parent.current_animation = parent.ANI_STATES.WALL_SLIDE
	else:
		parent.current_animation = parent.ANI_STATES.WALL_HUG

	_logger.info("Finished Wormed Processing Frame")



var climb_speed: float = 0.0



func climb_rope(delta: float, axis: float) -> bool:
	
	var point: PathFollow2D = parent.stuck_segment.path_point
	
	## Update Progress ratio based on axis
	# Up
	if axis > 0:
		
		
		climb_speed = move_toward(climb_speed, up_max_speed, up_accel * delta)
		
	
	# Down
	elif axis < 0:
		
		climb_speed = move_toward(climb_speed, down_max_speed, down_accel * delta)
		
	else:
		
		# Settle movement
		if climb_speed > 0:
			
			climb_speed = move_toward(climb_speed, 0, up_climb_friction * delta)
			
		elif climb_speed < 0:
			
			climb_speed = move_toward(climb_speed, 0, down_climb_friction * delta)
	
	#
	print(climb_speed)
	
	var ratio: float = point.progress_ratio
	
	point.progress_ratio -= climb_speed * delta
	print(point.progress_ratio)
	
	
	## Update Segment
	## Move up a segment
	if climb_speed > 0 and point.progress_ratio == 0.0:
		if parent.stuck_segment.prev: # readability
			parent.stuck_segment = parent.stuck_segment.prev
			parent.stuck_segment.path_point.progress_ratio = 1.0
	#
	## Move down a segment
	elif climb_speed < 0 and point.progress_ratio == 1.0:
			if parent.stuck_segment.next:
				parent.stuck_segment = parent.stuck_segment.next
				parent.stuck_segment.path_point.progress_ratio = 0.0
			elif climb_speed == down_max_speed:
				return true
	
	return false

## Called when an animation ends. How we handle transitioning to different animations
func animation_end() -> PlayerState:

	# If Jump Anim ends go to Falling
	if (parent.current_animation == parent.ANI_STATES.JUMP):
		parent.current_animation = parent.ANI_STATES.FALLING

	# If falling ends pause the animation
	if parent.current_animation == parent.ANI_STATES.FALLING:
		parent.restart_animation = true
		#parent.animation.pause()

	return null

func handle_jump(_delta) -> bool:

	

	# If the player has buffered a jump
	if parent.attempt_jump(-0.05):

		# Update Animation State if we aren't holding crawl still
		if (parent.current_animation != parent.ANI_STATES.CRAWL):
			parent.current_animation = parent.ANI_STATES.FALLING

		jump()
		
		return true
			
	return false


#perform rope jump
func jump():

	# Set Flags
	parent.jumping = true

	# Add a Horizontal Jump Boost to our players X velocity
	var jump_dir = parent.horizontal_axis
	if jump_dir == 0:
		jump_dir = -1 if parent.animation.flip_h else 1

	var vertical_multi = 1.0

	# Downward jump off rope
	if parent.vertical_axis < 0:
		vertical_multi = -0.4

	# Base Swing Multiplier
	var swing_multi: float = swing_min

	var jump_y_vel: float = parent.jump_velocity
	
	# But if they time the jump right :3
	# The goal of this is to simulate how horizontal velocity is highest
	if speeding_up:
		
		# As the players swing speed increases it gradually approaches 15
		# Normalized force value between 0 and 1
			# var t = swing_force / max_swing_force
			# var exponent = 3  # Adjust this exponent to control the growth rate
		
		
			# var exponential_multi = ((max_jump_multi - swing_multi) * pow(t, exponent)) + swing_multi
			# var exponential_multi = lerp(swing_min, max_jump_multi, swing_force/max_swing_force)
		
		var exponential_multi = max_jump_multi
		swing_multi = exponential_multi

		parent.set_temp_gravity(boost_sj_gravity)

		jump_y_vel = boost_sj_velocity

		# Set the flag cuz we wanna assume zoooming has started
		parent.boostJumping = true
	
	# else:

		# Set the gravity
		# if swing_jump_gravity:
			# parent.set_temp_gravity(swing_jump_gravity)

	if sign(parent.velocity.x) != sign(jump_dir):
		parent.velocity.x *= -1
	



	# Jump Velocity
	parent.velocity.y = jump_y_vel * vertical_multi

	# Jump horizontal boost
	if parent.boostJumping or speeding_up:
		parent.velocity.x += parent.movement_data.JUMP_HORIZ_BOOST * jump_dir * swing_multi
	else:
		parent.velocity.x = parent.movement_data.JUMP_HORIZ_BOOST * jump_dir * swing_multi


	# Jump SFX
	jumping_sfx.play(0)
	
	# Apply Impulse to the rope using func apply_rope_impulse(force)
	# Based on velocity
	apply_rope_impulse(parent.velocity * jump_force_multi)
	
	parent.squish_node.squish(Vector2(0.8, 1.2))
	
	# Animation
	parent.current_animation = parent.ANI_STATES.FALLING
	parent.restart_animation = true



# Set to true if we are moving "downward" or speeding up in the swing
var speeding_up: bool = false

var ret_force: float = 0.0

var period: float = 0.0
var pendulum_force: float = 0.0

var max_frequency = 5.0
var min_frequency = 2.5

func swinging(delta, dir):
	
	# Tie the players position to the rope
	var offset = Vector2(0, 8)
	parent.global_position = parent.stuck_segment.path_point.global_position + offset
	
	# Relative position to the ropes center
	var relative_position = round(parent.global_position - parent.stuck_segment.origin)
	
	
	# If we've moved down since last pool, and 
	if dir and sign(dir) != sign(relative_position.x) and relative_position.x != 0:

		
		# Increase the players swing force
		swing_force = move_toward(swing_force, max_swing_force, swing_down_accel * delta)
		speeding_up = true
		
		pendulum_force = swing_force
		
		var a = lerpf(min_frequency, max_frequency, pendulum_force/max_swing_force)
		# This is the coolest shit i've done
		if sign(dir) > 0:
			period = PI/(2*a) 
		else:
			period = (3*PI)/(2*a)
		
		# Set the glow
		parent.add_glow(0.1)
		
	
	else:
		
		# Decrease the players swing force
		swing_force = move_toward(swing_force, 600, swing_up_decel * delta)
		pendulum_force = min(pendulum_force, swing_force)
	
		# Register that the player is slowing down, used for discerning jump
		speeding_up = false
	
	
	# Update the sine sillyness
	period += delta
	
	
	# If the player is pushing in a direction
	if parent.horizontal_axis:
		
		var push_force: Vector2 = Vector2(swing_force,0)
		push_force *= dir
		apply_rope_force(push_force)
		
	# If the player is just letting the forces do what they do
	if not parent.horizontal_axis: #and round(relative_position.x) != 0:
		
		pendulum_force -= 1
		pendulum_force = max(pendulum_force, 0)
		
		var return_force: Vector2 = Vector2(pendulum_force, 0)
		
		var wave_length: float = 0.0
		wave_length = lerpf(min_frequency, max_frequency, pendulum_force/max_swing_force)
		
		# Holy Fuck my PreCalc professors would be so proud of me
		return_force *= sin(wave_length * period)
		apply_rope_force(return_force)
	
func apply_weight(_delta):

	apply_rope_force(Vector2(0, player_weight))


# Slowly move a players velocity towards zero the longer they're on rope
func velocity_decay(delta):
	parent.velocity.x = move_toward(parent.velocity.x, 0, parent.air_frict * delta)

func apply_rope_impulse(force: Vector2):
	
	var offset: Vector2 = Vector2.ZERO
	
	if parent.stuck_segment.next:
		offset.y = min(parent.stuck_segment.path_point.progress, 8)
	else:
		offset.y = min(parent.stuck_segment.path_point.progress, 4)
	
	parent.stuck_segment.apply_impulse(force, offset)

func apply_rope_force(force: Vector2):
	
	var offset: Vector2 = Vector2.ZERO
	
	if parent.stuck_segment.next:
		offset.y = min(parent.stuck_segment.path_point.progress, 8)
	else:
		offset.y = min(parent.stuck_segment.path_point.progress, 4)
	
	parent.stuck_segment.apply_force(force, offset)
