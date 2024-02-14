extends CharacterBody2D

@export_category("Movement Resource")
@export var movement_data : PlayerMovementData

@onready var animated = $AnimatedSprite2D
@onready var dust = $Dust

# Timers, fun because as the game gets faster the grace period will still be there
@onready var coyote_time = $CoyoteTime
@onready var jump_buffer = $JumpBuffer


# Calculating some constants
# Note these need to be switched when changing movement datas
@onready var FF_Vel = movement_data.JUMP_VELOCITY / movement_data.FASTFALL_MULTIPLIER


enum STATE {IDLE, WALKING, RUNNING, JUMPING, FALLING, LANDING, BEND, CROUCH, STAND}
var animation_state = STATE.IDLE

# In fast fall
var is_ff = false
var in_walljump = false
var cache_airdrift

var can_jump

# Momentum
# Momentum can scale Speed and Fast Fall Multiplier (I really like speed at 400, FF_Multi at 8)
var momentum_stage = 0



# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready():
	FF_Vel = movement_data.JUMP_VELOCITY / movement_data.FASTFALL_MULTIPLIER

func _physics_process(delta):
	
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var hz_direction = Input.get_axis("Left", "Right")
	var vc_direction = Input.get_axis("Down", "Up")
	
	# Start Jump Timer
	if (Input.is_action_just_pressed("Jump")):
		jump_buffer.start()
	
	# Add the gravity, direction used to calculate wall slide gravity
	apply_gravity(delta, hz_direction)

	# Handle jump.
	jump_logic(delta, hz_direction)
	hz_direction = walljump_logic(delta, hz_direction, vc_direction)
	

	# Handles Simple movement
	handle_acceleration(delta, hz_direction)
	apply_friction(delta, hz_direction)

	
	update_state(hz_direction)
	update_animations(hz_direction)
	
	var was_on_floor = is_on_floor()
	move_and_slide()
	var just_left_ledge = was_on_floor and not is_on_floor() and velocity.y >= 0
	if just_left_ledge:
		coyote_time.start()
	
	
func apply_gravity(delta, direction):
	
	if is_on_wall() and not Input.is_action_pressed("Jump"):
		if velocity.y > 0 and Input.is_action_pressed(get_which_wall_collided()):  # Ensure we're moving downwards
			velocity.y += gravity * delta * (1/movement_data.WALL_FRICTION_MULTIPLIER)  # Reduce the gravity's effect to slow down descent
		else:
			if not is_ff:
				velocity.y += gravity * delta
		
			else:
				velocity.y += gravity * movement_data.FASTFALL_MULTIPLIER * delta	
	
	# If we are just in the air use normal gravity
	elif not is_on_floor():
		if not is_ff:
			velocity.y += gravity * delta
	
		else:
			velocity.y += gravity * movement_data.FASTFALL_MULTIPLIER * delta
		
		
	

func jump_logic(delta, direction):
	# Handle jump.
	if is_on_floor() or coyote_time.time_left > 0.0:
		if Input.is_action_just_pressed("Jump") or jump_buffer.time_left > 0.0:
			
			# Prevent silly interactions between jumping and wall jumping
			jump_buffer.stop()
			jump_buffer.wait_time = -1
			
			velocity.y = movement_data.JUMP_VELOCITY
			
			if (animation_state != STATE.CROUCH):
				animation_state = STATE.JUMPING
	
	if not is_on_floor():
		if Input.is_action_just_released("Jump") and velocity.y < FF_Vel:
			
				FF_Vel = movement_data.JUMP_VELOCITY / movement_data.FASTFALL_MULTIPLIER
				velocity.y = FF_Vel
				
				if (animation_state != STATE.CROUCH):
					animation_state = STATE.JUMPING
		
		
func walljump_logic(delta, direction, vc_direction):	
	
	
	# In walljump
	if in_walljump:
		if velocity.y > 0:
			movement_data.AIR_DRIFT_MULTIPLIER = cache_airdrift
			print("falling")
	
	if is_on_wall_only():
		if Input.is_action_just_pressed("Jump") or jump_buffer.time_left > 0.0:
		
			# The vector for neutral wall jumps
			# 3., .75
			var neutralX = movement_data.NEUTRAL_WJ_VECTOR.x
			var neutralY = movement_data.NEUTRAL_WJ_VECTOR.y
			
			# The vector for away wall jumps
			# 10, .5
			var awayX = movement_data.AWAY_WJ_VECTOR.x
			var awayY = movement_data.AWAY_WJ_VECTOR.y
			
			var wall_normal = get_wall_normal()	
			# Prevent silly interactions between jumping and wall jumping
			jump_buffer.stop()
			jump_buffer.wait_time = -1
			
			# TODO: Walljump Animation (Crouch overrides all)
			if (animation_state != STATE.CROUCH):
				animation_state = STATE.JUMPING
			
			var jump_dir = wall_normal.x
				
			# Ok so if you are up on a walljump it'll launch you up
			if vc_direction > 0:
				velocity.y = movement_data.JUMP_VELOCITY * neutralY
				velocity.x = move_toward(velocity.x, (movement_data.SPEED * neutralX) * jump_dir, (movement_data.ACCEL * neutralX) * delta) 
				
				# Facing the fall we're jumping up
				if (movement_data.NEUTRAL_WJ_VECTOR.y < 1.7):
					animated.flip_h = (jump_dir > 0)
				else:
					animated.flip_h = (jump_dir < 0)
				
			# else itll launch you away
			else:
				velocity.y = movement_data.JUMP_VELOCITY * awayY
				velocity.x = move_toward(velocity.x, (movement_data.SPEED * awayX) * jump_dir, (movement_data.ACCEL * awayX * 1.5) * delta)
			
				# Face away from the wall we jumping off of
				animated.flip_h = (jump_dir < 0)
				
				
				in_walljump = true
				cache_airdrift = movement_data.AIR_DRIFT_MULTIPLIER
				movement_data.AIR_DRIFT_MULTIPLIER = 0.0
			
			return jump_dir
	return direction
			


			
func handle_acceleration(delta, direction):
	if direction and is_on_floor() and animation_state != STATE.CROUCH:
		# Floor ACCEL
		velocity.x = move_toward(velocity.x, movement_data.SPEED*direction, movement_data.ACCEL * delta)
	elif direction and not is_on_floor():
		# AIR ACCEL
		velocity.x  = move_toward(velocity.x, movement_data.SPEED*direction, (movement_data.ACCEL * movement_data.AIR_DRIFT_MULTIPLIER) * delta)
	elif direction and is_on_wall():
		# Wall Accel
		velocity.x  = move_toward(velocity.x, movement_data.SPEED*direction, (movement_data.ACCEL / movement_data.WALL_DRIFT_MULTIPLIER) * delta)
		
func apply_friction(delta, direction):
	
	# Ok this makes the game really slippery when changing direction
	if direction == 0:
		if is_on_floor():
			velocity.x = move_toward(velocity.x, 0, movement_data.FRICTION*delta)
		else:
			velocity.x = move_toward(velocity.x, 0, movement_data.AIR_RESISTANCE*delta)
			
	elif not direction * velocity.x > 0 and is_on_floor():
		print("changing directions")
		velocity.x = move_toward(velocity.x, 0, movement_data.TURN_FRICTION*delta)
		
	# If we are only touching a wall/holding into the wall
	#if is_on_wall_only(): 
	#	print("Applying wall friction")
	#	velocity.y = move_toward(velocity.y, gravity*1.5, movement_data.WALL_FRICTION_MULTIPLIER * delta )
	
		

func update_animations(direction):
	
	match animation_state:
		STATE.IDLE:
			animated.play("idle")
		STATE.RUNNING:
			animated.play("running")
		STATE.WALKING:
			animated.play("walking")
		STATE.JUMPING:
			animated.play("jump")
		STATE.FALLING:
			animated.play("falling")
		STATE.LANDING:
			animated.play("landing")
		STATE.BEND:
			animated.play("crouch")
		STATE.CROUCH:
			animated.play("crawl")
		STATE.STAND:
			animated.play("stand up")
	
	

func update_state(direction):
	
	if Input.is_action_just_pressed("Down") and not is_on_floor():
		is_ff = true
		animated.speed_scale = 2.0
	elif is_on_floor():
		is_ff = false
		
	# Change direction when on floor
	if direction > 0 and is_on_floor():
		animated.flip_h = false
		#dust.gravity.x = -200
	elif direction < 0 and is_on_floor():
		animated.flip_h = true
		#dust.gravity.x *= 200
	
	if direction and not is_on_floor() and animation_state != STATE.CROUCH:
		animation_state = STATE.FALLING
	
	# If set to running/walking from grounded state
	if direction and is_on_floor() and (animation_state == STATE.IDLE or animation_state == STATE.RUNNING or animation_state == STATE.WALKING):
		if abs(velocity.x) >= movement_data.SPEED/1.5:
			print("RUNNING!")
			animation_state = STATE.RUNNING
			dust.emitting = true
		else:
			print("WALKING!")
			animation_state = STATE.WALKING
			
	# Set to idle from walking
	if not direction and is_on_floor() and (animation_state == STATE.WALKING or animation_state == STATE.RUNNING) :
		animation_state = STATE.IDLE
	
	# So if we are in falling and we've touched the floor aggresively finish the animation
	if animation_state == STATE.FALLING and is_on_floor():
		animated.speed_scale = 2.0
		
		
	# Crawling Shit
	# When we press down we crouch
	if Input.is_action_just_pressed("Down") and is_on_floor():
		animation_state = STATE.BEND
		
	# Stay there til we let go of down
	if animation_state == STATE.CROUCH and Input.is_action_just_released("Down"):
		animation_state = STATE.STAND
		
	if animation_state != STATE.RUNNING:
		dust.emitting = false

func get_which_wall_collided():

	if get_wall_normal().x > 0.5:
		return "Left"
	elif get_wall_normal().x < -0.5:
		return "Right"


func _on_animated_sprite_2d_animation_finished():
	
	if animation_state == STATE.JUMPING:
		#animated.play("falling")
		print("Falling!")
		animation_state = STATE.FALLING
		
	if animation_state == STATE.FALLING and is_on_floor():
		print("Landing!")
		animation_state = STATE.LANDING

	if animation_state == STATE.LANDING and is_on_floor():
		print("Landed!")
		animated.speed_scale = 1
		
		
		animation_state = STATE.IDLE
		if velocity.x >= movement_data.SPEED/1.5:
			animation_state = STATE.RUNNING
		
	if animation_state == STATE.BEND and is_on_floor():
		animation_state = STATE.CROUCH
		
	if animation_state == STATE.STAND and is_on_floor():
		animation_state = STATE.IDLE
	
	if animation_state == STATE.STAND and not is_on_floor():
		animation_state = STATE.FALLING
