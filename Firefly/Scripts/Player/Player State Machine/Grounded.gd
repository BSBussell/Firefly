extends PlayerState

@export_subgroup("TRANSITIONAL STATES")
@export var AERIAL_STATE: PlayerState = null
@export var SLIDING_STATE: PlayerState = null

# And check the jump buffer on landing
@export_subgroup("Input Assists")
@export var jump_buffer: Timer
@export var coyote_time: Timer

# This one is used for things like "if the player jumps right before landing on a spring or rope
# Have them know the player just jumped if i wanna give a buffer for that
@export var post_jump_buffer: Timer

@onready var crouch_jump_window = $"../../Timers/CrouchJumpWindow"

# Particle Effects
@onready var dash_dust = $"../../Particles/DashDust"
@onready var jump_dust = $"../../Particles/JumpDustSpawner"
@onready var landing_dust = $"../../Particles/LandingDustSpawner"
@onready var speed_particles = $"../../Particles/MegaSpeedParticles"

# Sound Effects
@onready var landing_sfx = $"../../Audio/LandingSFX"
@onready var jumping_sfx = $"../../Audio/JumpingSFX"
@onready var run_sfx = $"../../Audio/RunSFX"


# Set to true when we are exiting via jumping
var jump_exit = false


# Called on state entrance, setup
func enter() -> void:
	
	if OS.is_debug_build():
		print("Grounded State")
	
	# Reset Flags
	jump_exit = false
	parent.crouchJumping = false
	parent.wallJumping = false
	
	# Setup the proper colliders for this state :3
	parent.set_standing_collider()
	
	# Also disable temp gravity when landing just incase we land without falling lol
	if parent.temp_gravity_active and parent.velocity.y >= 0:
		print("disabling temp_gravity")
		parent.temp_gravity_active = false
		parent.launched = false
		
		
	
	# If we're landing
	if parent.aerial:
		
		# Reset the flag
		parent.aerial = false
		
		# SFX
		landing_sfx.play(0)
	
		# Squish
		if jump_buffer.time_left == 0:
			parent.squish_node.squish(calc_landing_squish())
	
		# Check if we running :3
		if abs(parent.velocity.x) >= parent.run_threshold:
			parent.current_animation = parent.ANI_STATES.RUNNING
			dash_dust.emitting = true
		
		else:
			parent.current_animation = parent.ANI_STATES.LANDING

		# Give dust on landing
		var new_cloud = parent.LANDING_DUST.instantiate()
		new_cloud.set_name("landing_dust_temp_grounded")
		landing_dust.add_child(new_cloud)
		var animation = new_cloud.get_node("AnimationPlayer")
		animation.play("free")


# Called before exiting the state, cleanup
func exit() -> void:
	
	# Reset Effects
	run_sfx.stop()
	dash_dust.emitting = false

# Processing input in this state, returns nil or new state
func process_input(_event: InputEvent) -> PlayerState:
	
	# Crawling Shit
	# When we press down we crouch
	if Input.is_action_pressed("Down") and parent.current_animation != parent.ANI_STATES.CRAWL:
		return SLIDING_STATE
		
	return null


# Processing Physics in this state, returns nil or new state
func process_physics(delta: float) -> PlayerState:
	
	
	# Check for jumping
	jump_logic(delta)
	
	handle_acceleration(delta, parent.horizontal_axis)
	
	# Make sure we're on the floor
	# Then apply friction (helps to avoid launch being weird)
	if parent.is_on_floor():
		if (apply_friction(delta, parent.horizontal_axis) != null):
			return SLIDING_STATE
	
	#update_state(parent.horizontal_axis)
	
	
	# Make Sure we're still grounded after this
	if not parent.is_on_floor():
		
		# This is hard because we could either be falling or jumping in leaving this state
		# So lets be silly how we handle that.
		# Temp grav active check also ensures coyote time isn't started on launch
		if not jump_exit and not parent.temp_gravity_active:
			coyote_time.start()
		
		return AERIAL_STATE
	
	# If for whatever reason we end up not having room above us then force the
	# Player into crouch, might be used with Auto entering tunnel
	if not AERIAL_STATE.have_stand_room():
		return SLIDING_STATE
	
		
	return null
	
func process_frame(delta):
	
	update_state(parent.horizontal_axis)
	
	if abs(parent.velocity.x) > parent.speed:
		speed_particles.emitting = true
		speed_particles.direction.x = 1 if (parent.animation.flip_h) else -1
	else:
		speed_particles.emitting = false
	
## Updates animation states based on changes in physics
func update_state(direction):
	
	update_facing(direction)
	update_run_effects(direction)
	
	
		
func update_facing(direction: float) -> void:
	
	# Change direction
	if direction > 0 and parent.animation.flip_h:
		parent.animation.flip_h = false
		parent.squish_node.squish(parent.turn_around_squash)
		
	elif direction < 0 and not parent.animation.flip_h:
		parent.animation.flip_h = true
		parent.squish_node.squish(parent.turn_around_squash)

func update_run_effects(direction: float) -> void:
	# If set to running/walking from grounded state
	if direction:
		if parent.current_animation == parent.ANI_STATES.IDLE or parent.current_animation == parent.ANI_STATES.RUNNING or parent.current_animation == parent.ANI_STATES.WALKING or parent.current_animation == parent.ANI_STATES.STANDING_UP:
			
			
			# Making this a variable so its not computed twice (theres a good change the interpreter would've already done this :3)
			var at_run_threshold: bool = abs(parent.velocity.x) >= parent.run_threshold
			
			# If we're running and not already in running
			if at_run_threshold and parent.current_animation != parent.ANI_STATES.RUNNING:
				
				# Set animation and sfx
				parent.current_animation = parent.ANI_STATES.RUNNING
				run_sfx.play()
				
				# Start our Dust!
				dash_dust.emitting = true
				
			elif not at_run_threshold:
				parent.current_animation = parent.ANI_STATES.WALKING
			
	# Set to idle from walking
	if not direction:
		if (parent.current_animation == parent.ANI_STATES.RUNNING or parent.current_animation == parent.ANI_STATES.WALKING) :
			parent.current_animation = parent.ANI_STATES.IDLE
			run_sfx.stop()
		
	# If we're not walking go to runnings
	if parent.current_animation != parent.ANI_STATES.RUNNING:
		dash_dust.emitting = false
	
# Our logic for making the player jumping
func jump_logic(_delta):
	
	# If a jump has been buffered, and we aren't being launched by something else
	if not parent.launched and parent.attempt_jump():
		
		grounded_jump()
			
	

## Make the player jump
func grounded_jump():
	
	# Set our flags
	jump_exit = true
	parent.jumping = true
	
	
	# Actual Jump Forces
	parent.velocity.y = parent.jump_velocity
	parent.velocity.x += parent.movement_data.JUMP_HORIZ_BOOST * parent.horizontal_axis
	
	
	# Dust Effect
	var new_cloud = parent.JUMP_DUST.instantiate()
	new_cloud.set_name("jump_dust_temp")
	jump_dust.add_child(new_cloud)
	var animation = new_cloud.get_node("AnimationPlayer")
	animation.play("free")
	
	# Jump SFX
	jumping_sfx.play(0)
	
	# Squishy
	parent.squish_node.squish(parent.jump_squash)
	
	# If we're not currently crouching, then we initiate jumping
	if (parent.current_animation != parent.ANI_STATES.CRAWL):
		parent.current_animation = parent.ANI_STATES.FALLING
	
	post_jump_buffer.start()
	
# Accelerate the player based on direction
func handle_acceleration(delta, direction):
	
	# If direction is different than velocity (turning around)
	if direction and parent.velocity.x and sign(direction) != sign(parent.velocity.x):
		
		print("Turning Around")
		var accel: float = parent.accel * 4
		var speed: float = parent.speed
		# Increasing speed
		print(parent.velocity.x)
		parent.velocity.x = move_toward(parent.velocity.x, speed*direction, accel * delta)
		print(parent.velocity.x)
	
	elif direction:  
		
		if (abs(parent.velocity.x) > parent.speed and sign(parent.velocity.x) == sign(direction)):
			# Reducing Speed to the cap 
			parent.velocity.x = move_toward(parent.velocity.x, parent.speed*direction, parent.movement_data.SPEED_REDUCTION * delta)
		else:
			
			var accel: float = parent.accel
			var speed: float = parent.speed
			
			var slope_angle = rad_to_deg(parent.get_floor_angle(Vector2.UP))

			var speed_mod: float = 1.0
			var accel_mod: float = 1.0
			
			# At 45 degrees start slowing down acceleration based on the steepness
			if slope_angle > 50 and slope_angle < 90:
				if sign(parent.get_floor_normal().x) != sign(direction):  # Uphill
					speed_mod = lerp(1.0, 0.5, min(slope_angle, 90) / 90)
					accel_mod = lerp(1.0, 0.5, min(slope_angle, 90) / 90)
					
				else:  # Downhill
					speed_mod = lerp(1.0, 1.5, min(slope_angle, 90) / 90)
					accel_mod = lerp(1.0, 1.5, min(slope_angle, 90) / 90)
			
			speed *= speed_mod
			accel *= accel_mod
			
			# Increasing speed
			parent.velocity.x = move_toward(parent.velocity.x, speed*direction, accel * delta)
	
# Stop the character when they let go of the button
func apply_friction(delta, direction) -> PlayerState:
	
	parent.turningAround = false
	
	
	# Ok this makes the game really slippery when changing direction
	if not direction:
		
			# IF LEVEL GROUND
			
			var slope_angle = rad_to_deg(parent.get_floor_angle(Vector2.UP))			
			if slope_angle < 60:
				
				# Apply our usual friction
				parent.velocity.x = move_toward(parent.velocity.x, 0, parent.friction * delta)
			
			# Sliding Downhill
			else:
				
				var sign = sign(parent.get_floor_normal().x)
				parent.animation.flip_h = sign(parent.get_floor_normal().x) <= 0 # Flip the sprite based on slide dir
				
				var speed = sign * parent.hill_speed
				var accel = parent.hill_accel
				
				parent.velocity.x = move_toward(parent.velocity.x, speed, accel*delta)
				
				return SLIDING_STATE
				
		
	# IF Turning around
	elif not (direction * parent.velocity.x > 0):
		parent.turningAround = true
		#parent.velocity.x = move_toward(parent.velocity.x, 0, parent.turn_friction)
		
	return null
	
		



func animation_end() -> PlayerState:
	
	# If we've stopped landing then we go to idle animations
	if parent.current_animation == parent.ANI_STATES.LANDING:
		parent.current_animation = parent.ANI_STATES.IDLE
		
		
	# If we've stopped getting up then we go to our idle
	if parent.current_animation == parent.ANI_STATES.STANDING_UP:
		parent.current_animation = parent.ANI_STATES.IDLE
	
	# Sometimes we exit with slide end, in this case we goto idle :3
	if parent.current_animation == parent.ANI_STATES.SLIDE_END:
		parent.current_animation = parent.ANI_STATES.IDLE
	
	return null

## Funny Method for calculating the landing squish using lerps
func calc_landing_squish() -> Vector2:
	
	var squish_blend = abs(parent.landing_speed) / parent.movement_data.MAX_FALL_SPEED
	var x_squish = lerp(1.0, parent.landing_squash.x, squish_blend)
	var y_squish = lerp(1.0, parent.landing_squash.y, squish_blend)
	return Vector2(x_squish, y_squish)
