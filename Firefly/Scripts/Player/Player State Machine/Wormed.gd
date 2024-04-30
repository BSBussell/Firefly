extends PlayerState

@export_subgroup("DEPENDENT STATES")
@export var AERIAL_STATE: PlayerState = null


@export var swing_force: float = 400
@export var max_swing_force: float = 2000
@export var min_swing_force: float = 600
@export var swing_down_accel: float = 1200
@export var swing_up_decel: float = 800
@export var player_weight: float = 980

@export var grab_force_multi: float = 1.75
@export var jump_force_multi: float = -1.75


# Effects
@onready var speed_particles = $"../../Particles/MegaSpeedParticles"
@onready var jump_dust = $"../../Particles/JumpDustSpawner"
@onready var jumping_sfx = $"../../Audio/JumpingSFX"

# Rope Detector
@onready var rope_detector = $"../../Physics/RopeDetector"

@onready var swinging_sfx = $"../../Audio/SwingingSFX"
@onready var rope_creak_sfx = $"../../Audio/RopeCreakSFX"


# Called on state entrance, setup
func enter() -> void:
	
	
	
	if OS.is_debug_build():
		print("Wormed State")

	# Reset this value with silly number that hz axis will never be
	slow_dir = 5.0
	last_position= Vector2.ZERO

	parent.set_standing_collider()

	
	rope_detector.set_collision_mask_value(9, false)	
	
	var speed_ratio = min(abs(parent.velocity.x) / (parent.air_speed * 2.5), 1.0)
	swing_force = lerpf(min_swing_force, max_swing_force, speed_ratio)
	

	apply_rope_impulse(parent.velocity * grab_force_multi)


	#swinging_sfx.pitch_scale = 1.75 if swinging_sfx.pitch_scale != 1.75 else 2
	#swinging_sfx.play()
	
	rand_from_seed(parent.stuck_segment.global_position.x)
	rope_creak_sfx.pitch_scale = randf_range(1, 2)
	rope_creak_sfx.play()

	
	# Put us in the falling animation if we are not crouch jumping, jumping, or if we're launched
	parent.current_animation = parent.ANI_STATES.WALL_SLIDE
	parent.restart_animation = true
		


	


# Called before exiting the state, cleanup
func exit() -> void:

	
	# And any potentially on particles
	speed_particles.emitting = false

	parent.stuck_segment.start_cooldown(0.2)
	parent.stuck_segment = null
	
	 #Wait 0.3 seconds before we can grab a rope again
	#await get_tree().create_timer(0.2).timeout
	
	print("wtf")
	rope_detector.set_collision_mask_value(9, true)
	
	
	rope_creak_sfx.stop()

	


# Processing input in this state, returns nil or new state
func process_input(_event: InputEvent) -> PlayerState:


	if Input.is_action_just_pressed("Down"):
		if parent.stuck_segment.next:
			parent.stuck_segment = parent.stuck_segment.next
		else:
			return AERIAL_STATE

	if Input.is_action_just_pressed("Up"):
		if parent.stuck_segment.prev:
			parent.stuck_segment = parent.stuck_segment.prev

	return null

# Processing Physics in this state, returns nil or new state
func process_physics(delta: float) -> PlayerState:



	# Swing
	swinging(delta, parent.horizontal_axis)
	
	apply_weight(delta)
	
	velocity_decay(delta)
	

	# Water State Change Handled by the Water Detection
	if handle_jump(delta):
		return AERIAL_STATE
		
	return null




func process_frame(_delta):

	

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
	if abs(parent.velocity.x) > parent.air_speed + parent.movement_data.JUMP_HORIZ_BOOST or parent.temp_gravity_active:
		speed_particles.emitting = true
		speed_particles.direction.x = 1 if (parent.animation.flip_h) else -1
	else:
		speed_particles.emitting = false

	if parent.horizontal_axis:
		parent.current_animation = parent.ANI_STATES.WALL_SLIDE
	else:
		parent.current_animation = parent.ANI_STATES.WALL_HUG

	pass

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
	if parent.attempt_jump():

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
	
	# The player should be able to do a lot regardless
	# with swinging
	var swing_multi = 3.5
	
	# But if they time the jump right :3
	# This isn't generally base game stuff
	# More like silly fun zoom stuff
	if speeding_up and sign(parent.horizontal_axis) == sign(fall_dir):
		swing_multi = lerpf(swing_multi, 10, swing_force/max_swing_force)
		print("Swing Boost!")

	if sign(parent.velocity.x) != sign(jump_dir):
		parent.velocity.x *= -1
	
	parent.velocity.x += parent.movement_data.JUMP_HORIZ_BOOST * jump_dir * swing_multi


	var vertical_control = 1.0
	if parent.vertical_axis < 0:
		vertical_control = -0.4
		

	# Jump Velocity
	parent.velocity.y = parent.jump_velocity * vertical_control

	
	# TODO: Water Jump :3
	# Jump SFX
	jumping_sfx.play(0)
	
	# Apply Impulse to the rope using func apply_rope_impulse(force)
	# Based on velocity
	apply_rope_impulse(parent.velocity * jump_force_multi)
	
	parent.squish_node.squish(Vector2(0.8, 1.2))
	
	# Animation
	parent.current_animation = parent.ANI_STATES.FALLING
	parent.restart_animation = true


var last_position: Vector2 = Vector2.ZERO

# Set to the direction that makes us fall down
var slow_dir = 5.0

var speeding_up: bool = false
var fall_dir: int = 0
var hz_speed: float = 0.0
func swinging(delta, dir):
	
	var offset = Vector2(0, -16)
	parent.global_position = parent.stuck_segment.global_position - offset
	
	# If we've moved down since last pool, and 
	if parent.global_position.y > last_position.y and slow_dir != parent.horizontal_axis:
		swing_force = move_toward(swing_force, max_swing_force, swing_down_accel * delta)
		print("Swing Speed Up")
		speeding_up = true
		
		# Find which direction we're moving towards
		hz_speed = parent.global_position.x - last_position.x
		fall_dir = sign(hz_speed)
		
		#slow_dir = -parent.horizontal_axis
		
	else:
		swing_force = move_toward(swing_force, 600, swing_up_decel * delta)
	
		
		
		
		#if parent.global_position.y > last_position.y:
			#slow_dir = -parent.horizontal_axis
		
		speeding_up = false
	
		print("Swing Slow Down:")
		print("Swing Pos Bool: ", parent.global_position.y > last_position.y)
		#print("Swing Dir Bool: ", current_dir != parent.horizontal_axis)
	
	# Register that this direction slows us down now
	if parent.global_position.y <= last_position.y:
		slow_dir = sign(parent.global_position.x - last_position.x)
		print("Swing Set Slow Dir: ", slow_dir)
	
	last_position = parent.global_position
	
	if parent.horizontal_axis:
		
		var grab_force: Vector2 = Vector2(swing_force,0)
		grab_force *= dir
		apply_rope_force(grab_force)
	
func apply_weight(delta):

	apply_rope_force(Vector2(0, player_weight))


# Slowly move a players velocity towards zero the longer they're on rope
func velocity_decay(delta):
	parent.velocity.x = move_toward(parent.velocity.x, 0, parent.air_frict * delta)

func apply_rope_impulse(force: Vector2):
	
	var offset: Vector2 = Vector2.ZERO
	parent.stuck_segment.apply_impulse(force, offset)

func apply_rope_force(force: Vector2):
	
	var offset: Vector2 = Vector2.ZERO
	parent.stuck_segment.apply_force(force, offset)
