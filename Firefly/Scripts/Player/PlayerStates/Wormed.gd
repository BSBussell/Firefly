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

@export_category("Swing Physics Values")
@export var player_weight: float = 980

@export var grab_force_multi: float = 1.75
@export var jump_force_multi: float = -1.75

@export var max_swing_force: float = 2000
@export var min_swing_force: float = 400
@export var swing_pump_accel: float = 1200
@export var swing_decel: float = 200


## How often the rope swings back and forth
@export_group("Swing Period Settings")
## Multiplier for how long one "swing" cycle should last
@export var base_period_multi: float = 1.0

## Value for how fast the "swing cycle" should be smoothed towards the target
@export var base_period_accel: float = 2.0


@export var pumping_period_multi: float = 1.1
@export var pumping_period_accel: float = 2

@export var init_boosted_period_multi: float = 3.5
@export var boosted_period_multi: float = 1.1
@export var boosted_period_accel: float = 6.0


# The player should be able to do a lot regardless
# of swinging
@export_category("Swing Jump Properties")
## The base multiplier when jumping off a rope
@export var base_jump_multi: float = 3
## The max multiplier when jumping off a rope at the right timing.
@export var boost_jump_multi: float = 11
@export var nyoom_jump_multi: float = 9

## Height of jumping off a rope
@export var swing_jump_height: float = 2.0
@export var swing_jump_rise_time: float = 0.2
@export var boosted_sj_height: float = 2.0
@export var boost_sj_rise_time: float = 0.29

## Horizontal Velocity Multiplier
@export var boost_sj_velocity_cost: float = 0.9
@export var boost_sj_vel_rev_cost: float = 0.8


# Effects
@onready var speed_particles: CPUParticles2D = $"../../Particles/SpeedParticles"
@onready var jump_dust: Marker2D = $"../../Particles/JumpDustSpawner"
@onready var jumping_sfx: AudioStreamPlayer2D = $"../../Audio/JumpingSFX"

# Rope Detector
@onready var rope_detector: Area2D = $"../../Physics/RopeDetector"
@onready var rope_tighten_sfx: AudioStreamPlayer2D = $"../../Audio/RopeTightenSFX"
@onready var rope_creak_sfx: AudioStreamPlayer2D = $"../../Audio/RopeCreakSFX"


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


var climb_speed: float = 0.0

# Called on state entrance, setup
func enter() -> void:
	
	
	
	if OS.is_debug_build():
		_logger.info("Wormed State")

	# We are not speeding up on grab
	speeding_up = false
	
	parent.set_standing_collider()

	# Make us unable to grab another rope
	rope_detector.set_deferred("monitoring", false)
	
	climb_speed = 0.0
	
	var speed_ratio = min(abs(parent.velocity.x) / (parent.air_speed * 2.5), 1.0)
	pendulum_force = snappedf(lerpf(min_swing_force * 2, max_swing_force, speed_ratio), 1)
	
	
	# Relative position to the ropes center
	var a = lerpf(min_frequency, max_frequency, pendulum_force/max_swing_force)
	# This is the coolest shit i've done
	if sign(parent.velocity.x) > 0:
		period = PI/(2*a) 
	else:
		period = (3*PI)/(2*a)
			
	

	apply_rope_impulse(parent.velocity * grab_force_multi)
	
	
	if parent.boostJumping:
		period_multi = 3.5

	
	rand_from_seed(int(parent.stuck_segment.root.global_position.x))
	rope_creak_sfx.pitch_scale = randf_range(1, 2)
	rope_creak_sfx.play()
	
	
	rope_tighten_sfx.pitch_scale = randf_range(1.1, 2)
	rope_tighten_sfx.play()

	
	# Grab rope animation
	parent.current_animation = parent.ANI_STATES.WALL_HUG
	parent.restart_animation = true
		
	_logger.info("We have finished Enter")


	


# Called before exiting the state, cleanup
func exit() -> void:

	# And any potentially on particles
	speed_particles.emitting = false

	parent.stuck_segment.start_cooldown(0.2)
	parent.stuck_segment = null
	
	
	rope_detector.set_deferred("monitoring", true)
	
	rope_creak_sfx.stop()

	parent.rotation = 0.0

	_logger.info("Flyph - Worm Exit")

	


# Processing Physics in this state, returns nil or new state
func process_physics(delta: float) -> PlayerState:

	_logger.info("Wormed Process Physics")

	if climb_rope(delta, parent.vertical_axis):
		return AERIAL_STATE

	# Swing
	swinging(delta, parent.horizontal_axis)
	
	apply_weight(delta)
	
	velocity_decay(delta)

	# Enable player jumping off rope
	if handle_jump(delta):

		_logger.info("Finished Wormed Process Physics - Jumping")

		return AERIAL_STATE
		
	_logger.info("Finished Wormed Process Physics")

	return null




func process_frame(_delta):

	_logger.info("Wormed Process Frame")

	update_direction()
	particle_emission()
	update_sprite()

	_logger.info("Finished Wormed Processing Frame")


func update_direction() -> void:
	# Direction Facing, don't update if we're walljumping up
	if not (parent.wallJumping and parent.current_wj == parent.WALLJUMPS.UPWARD):
		
		if parent.horizontal_axis < 0 and not parent.animation.flip_h:
			
			rope_creak_sfx.play(rope_creak_sfx.get_playback_position())
			
			parent.animation.flip_h = true
			parent.squish_node.squish(parent.turn_around_squash)
			parent.current_animation = parent.ANI_STATES.SWING
			

		elif parent.horizontal_axis > 0 and parent.animation.flip_h:
			
			rope_creak_sfx.play(rope_creak_sfx.get_playback_position())
			
			parent.animation.flip_h = false
			parent.squish_node.squish(parent.turn_around_squash)
			
			parent.current_animation = parent.ANI_STATES.SWING
	

func particle_emission() -> void:
	# Speed Particle Emission
	if abs(parent.velocity.x) > parent.air_speed + parent.movement_data.JUMP_HORIZ_BOOST or parent.temp_gravity_active or speeding_up:
		speed_particles.emitting = true
		speed_particles.direction.x = 1 if (parent.animation.flip_h) else -1
	else:
		speed_particles.emitting = false

func update_sprite() -> void:
	
	if climb_speed > 0:
		parent.current_animation = parent.ANI_STATES.CLIMB
	
	elif climb_speed < 0:
		parent.current_animation = parent.ANI_STATES.WALL_SLIDE
	
	#elif parent.horizontal_axis:
		#parent.current_animation = parent.ANI_STATES.SWING
	elif not parent.horizontal_axis:
		parent.current_animation = parent.ANI_STATES.WALL_HUG
		


func climb_rope(delta: float, axis: float) -> bool:
	
	var point: PathFollow2D = parent.stuck_segment.path_point
	
	# variables assigned 
	var velocity: float = 0.0
	var accel: float = 0.0
	
	## Update Progress ratio based on axis
	# Up
	if axis > 0:
		
		velocity = up_max_speed
		accel = up_accel
		
	# Down
	elif axis < 0:
		
		velocity = down_max_speed
		accel = down_accel
		
	else:
		
		# We move towards 0 speed
		velocity = 0
		
		# Assign accel based on the direction we were moving
		if climb_speed > 0: accel = up_climb_friction
		elif climb_speed < 0: accel = down_climb_friction
	
	climb_speed = move_toward(climb_speed, velocity, accel * delta)
	
	point.progress_ratio -= climb_speed * delta
	
	
	## Update Segment
	# Move up a segment
	if climb_speed > 0 and point.progress_ratio == 0.0:
		if parent.stuck_segment.prev: # readability if
			parent.stuck_segment = parent.stuck_segment.prev
			parent.stuck_segment.path_point.progress_ratio = 1.0
	
	# Move down a segment
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

	# Jump in the direction we are facing or the direction we are holding
	var jump_dir = parent.horizontal_axis
	
	# If we're holding no direcrtion
	if jump_dir == 0:
		
		# Sorry no more boost :<
		parent.boostJumping = false
		
		# Jumping in the direction we're facing 
		jump_dir = -1 if parent.animation.flip_h else 1

	# The base multiplier for jump height
	var vertical_multi = 1.0

	

	# Base Swing Multiplier
	var swing_multi: float = base_jump_multi

	# Base Jump y vel
	var jump_y_vel: float = parent.jump_velocity
	
	# If holding down, then we have a negative multiplier to jump down from rope
	if parent.vertical_axis < 0:
		vertical_multi = -0.4
	
	# If the player jumps while holding towards center rope
	if speeding_up:
		
		# If we already boosting, then we ascend to nyooming
		swing_multi = boost_jump_multi if not parent.boostJumping else nyoom_jump_multi

		parent.set_temp_gravity(boost_sj_gravity)

		jump_y_vel = boost_sj_velocity

		# Set the flag cuz we wanna assume zoooming has started
		parent.boostJumping = true
	

	# Flip player x velocity if we are jumping in the opposite direction
	# Multiply by velocity cost to improve feel a little
	if sign(parent.velocity.x) != sign(jump_dir):
		parent.velocity.x *= -boost_sj_vel_rev_cost
	else:
		parent.velocity.x *= boost_sj_velocity_cost
	

	# Set Vertical Velocity
	parent.velocity.y = jump_y_vel * vertical_multi

	# Jump horizontal boost, additive if we're in "boost jumping" state
	if parent.boostJumping:
		
		
		
		parent.velocity.x += parent.movement_data.JUMP_HORIZ_BOOST * jump_dir * swing_multi
	else:
		parent.velocity.x = parent.movement_data.JUMP_HORIZ_BOOST * jump_dir * swing_multi

	
	#parent.lock_h_dir(jump_dir, 0.2, true )

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
var return_force: Vector2 = Vector2.ZERO

var max_frequency = 5.0
var min_frequency = 4.0
var period_multi: float = 1.0	



# Calculus
func swinging(delta, dir):
	
	# Tie the players position to the rope
	var offset = Vector2(4, 6)
	
	if not parent.animation.flip_h:
		offset.x *= -1
		
	parent.global_position = parent.stuck_segment.path_point.global_position
	
	# Relative position to the ropes center
	var relative_position = round(parent.global_position - parent.stuck_segment.origin)
	
	parent.global_position += offset 
	
	parent.rotation = parent.stuck_segment.rotation
	parent.rotation_degrees = max(min(parent.rotation_degrees, 4), -4)
		
	var target_period_multi: float = base_period_multi
	var period_accel: float = base_period_accel
	
		
	# Pretty much if we're holding in direction of center
	speeding_up = dir and sign(dir) != sign(relative_position.x) and relative_position.x != 0
	speeding_up = speeding_up and sign(dir) == sign(return_force.x)

	# If we've moved down since last pool, and 
	if speeding_up:

		# Increase the pendulum force
		pendulum_force = move_toward(pendulum_force, max_swing_force, swing_pump_accel * delta)
		
		target_period_multi = pumping_period_multi
		period_accel = pumping_period_accel
		
		# Add a bit of glow
		parent.add_glow(0.15)
		
	
	
	## If we've launched from a rope or if we've slide boosted our way to the rope
	if parent.boostJumping:
		target_period_multi = boosted_period_multi
		period_accel = boosted_period_accel
	
	
	# Smooth period changes
	period_multi = move_toward(period_multi, target_period_multi, period_accel * delta)
	
	# Update the period variable
	period += delta * period_multi
	
	pendulum_force = move_toward(pendulum_force, min_swing_force, delta * swing_decel)
	
	return_force = Vector2(pendulum_force, 0)
	
	var wave_length: float = min_frequency
	return_force *= sin(wave_length * period)
	
	apply_rope_force(return_force)
	
func apply_weight(_delta):

	apply_rope_force(Vector2(0, player_weight))


# Slowly move a players velocity towards zero the longer they're on rope
func velocity_decay(delta):
	
	# Enables players to leave the rope in time if they want to maintain a state of nyoom
	if parent.boostJumping:
		parent.velocity.x = move_toward(parent.velocity.x, 0, parent.air_frict * delta * 0.25)
	
	# But if they aren't nyooming then just restart them
	else:
		parent.velocity.x = 0
		
	# When velocity reaches 0 remove bj privs
	if parent.velocity.x == 0: parent.boostJumping = false

func apply_rope_impulse(force: Vector2):
	
	var offset: Vector2 = Vector2.ZERO
	
	if parent.stuck_segment.next:
		offset.y = min(parent.stuck_segment.path_point.progress, 8)
	else:
		offset.y = min(parent.stuck_segment.path_point.progress, 2)
	
	parent.stuck_segment.apply_impulse(force, offset)

func apply_rope_force(force: Vector2):
	
	var offset: Vector2 = Vector2.ZERO
	
	if parent.stuck_segment.next:
		offset.y = min(parent.stuck_segment.path_point.progress, 8)
	else:
		offset.y = min(parent.stuck_segment.path_point.progress, 2)
	
	parent.stuck_segment.apply_force(force, offset)
