extends PlayerState

@export_subgroup("DEPENDENT STATES")
@export var AERIAL_STATE: PlayerState = null



# Effects
@onready var speed_particles = $"../../Particles/MegaSpeedParticles"
@onready var jump_dust = $"../../Particles/JumpDustSpawner"
@onready var jumping_sfx = $"../../Audio/JumpingSFX"

# Rope Detector
@onready var rope_detector = $"../../Physics/RopeDetector"

var swing_force: float = 400
var max_swing_force: float = 2000
var swing_down_accel: float = 1200
var swing_up_decel: float = 800

# Called on state entrance, setup
func enter() -> void:
	
	
	
	if OS.is_debug_build():
		print("Wormed State")


	parent.set_standing_collider()

	
	rope_detector.set_collision_mask_value(9, false)	
	print("AirSpeed: ", parent.air_speed * 1.5)
	var speed_ratio = min(abs(parent.velocity.x) / (parent.air_speed * 1.5), 1.0)
	swing_force = lerpf(600, max_swing_force, speed_ratio)
	print("Speed, Ratio: ", speed_ratio)
	print("Entry Swing Force: ", swing_force)

	var grab_force: Vector2 = Vector2(600,0)
	grab_force *= sign(parent.velocity.x)
	apply_rope_impulse(parent.velocity * 1.75)

	
	# Put us in the falling animation if we are not crouch jumping, jumping, or if we're launched
	parent.current_animation = parent.ANI_STATES.WALL_SLIDE
	parent.restart_animation = true
		


	


# Called before exiting the state, cleanup
func exit() -> void:

	
	# And any potentially on particles
	speed_particles.emitting = false

	parent.stuck_segment = null
	
	# Wait 0.3 seconds before we can grab a rope again
	await get_tree().create_timer(0.2).timeout
	
	print("wtf")
	rope_detector.set_collision_mask_value(9, true)

	


# Processing input in this state, returns nil or new state
func process_input(_event: InputEvent) -> PlayerState:


	


	return null

# Processing Physics in this state, returns nil or new state
func process_physics(delta: float) -> PlayerState:



	# Swing
	swinging(delta, parent.horizontal_axis)
	
	# Jump off thing
	

	# Water State Change Handled by the Water Detection
	if handle_jump(delta):
		return AERIAL_STATE
		
	return null




func process_frame(_delta):

	

	# Direction Facing, don't update if we're walljumping up
	if not (parent.wallJumping and parent.current_wj == parent.WALLJUMPS.UPWARD):
		if parent.velocity.x < 0 and not parent.animation.flip_h:
			parent.animation.flip_h = true
			parent.squish_node.squish(parent.turn_around_squash)

		elif parent.velocity.x > 0 and parent.animation.flip_h:
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

	# If we are able to do a coyote jump
	if not parent.launched:

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
	
	
	var swing_multi = lerpf(1, 3, swing_force/max_swing_force)
	print("Swing_Mult: ", swing_multi)
	parent.velocity.x = parent.movement_data.JUMP_HORIZ_BOOST * jump_dir * swing_multi

	# Jump Velocity
	parent.velocity.y = parent.jump_velocity

	
	# TODO: Water Jump :3
	# Jump SFX
	jumping_sfx.play(0)
	
	# Apply Impulse to the rope using func apply_rope_impulse(force)
	# Based on velocity
	apply_rope_impulse(parent.velocity * -1.75)
	
	parent.squish_node.squish(Vector2(0.8, 1.2))
	
	# Animation
	parent.current_animation = parent.ANI_STATES.FALLING
	parent.restart_animation = true


var last_position: Vector2 = Vector2.ZERO
func swinging(delta, dir):
	
	var offset = Vector2(0, -16)
	parent.global_position = parent.stuck_segment.global_position - offset
	
	if parent.global_position.y > last_position.y:
		swing_force = move_toward(swing_force, max_swing_force, swing_down_accel * delta)
		print("Moving Down")
	else:
		swing_force = move_toward(swing_force, 600, swing_up_decel * delta)
	
		print("Stalling or moving up")
	
	last_position = parent.global_position
	
	if parent.horizontal_axis:
		
		var grab_force: Vector2 = Vector2(swing_force,0)
		grab_force *= parent.horizontal_axis
		apply_rope_force(grab_force)
	


func apply_rope_impulse(force: Vector2):
	
	var offset: Vector2 = Vector2.ZERO
	print(force)
	#parent.stuck_segment.apply_central_impulse(force)
	parent.stuck_segment.apply_impulse(force, offset)

func apply_rope_force(force: Vector2):
	
	var offset: Vector2 = Vector2.ZERO
	print(force)
	#parent.stuck_segment.apply_central_impulse(force)
	parent.stuck_segment.apply_force(force, offset)
