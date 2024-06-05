class_name Glow_Manager
extends Node

## The sample size for calculating the score average
@export var SPEED_SAMPLE_SIZE: int = 5

## How often we pool speed for a new average
@export var SPEED_POLL_RATE: float = 0.2

@export var MOMENTUM_TIMER: Timer

@onready var PLAYER: Flyph = $".."


@onready var glow_aura = $"../Particles/GlowAura"
@onready var promotion_fx = $"../Particles/PromotionFx"

signal glow_meter_changed(new_value: float)
signal glow_promote()

# Players Movement Score
var movement_level: int = 0
var max_level: int
var score: float = 0

var score_sample: SampleArray
var poll_count: float = 0.0

var auto_glow: bool = false

var GLOW_ENABLED: bool = true



var glow_points: float = 0
var glow_points_max: float = 100
var glow_grow_rate: float = 5
var glow_decay_rate: float = 5

var decaying = false
var exponential_decay: float = 0.0

var surplus_multiplier: float = 2.0


var meter = null




# Can be called whenever we want to restart the movement system
func startup():
	
	max_level =  len(PLAYER.movement_states) - 1
	
	glow_grow_rate = PLAYER.movement_data.GLOW_GROWTH_RATE
	glow_decay_rate = PLAYER.movement_data.GLOW_DECAY_RATE
	
	MOMENTUM_TIMER.stop()
	
	# Initialize our sample array
	score_sample = SampleArray.new(SPEED_SAMPLE_SIZE)
	
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	
	# If we haven't enabled glow yet then we don't do anything
	if not GLOW_ENABLED:
		return
	
	# Update Scoring information based on movement speed, etc.
	score = calc_score()
	
	if poll_count >= SPEED_POLL_RATE:
		score_sample.add_element(score)
		poll_count = 0
		
		print("Score Average: ", score_sample.get_average())
		
	poll_count += delta
	
	var new_points = score * glow_grow_rate
	
	# Add score to points, score only goes up if we're at max level
	glow_points = move_toward(glow_points, glow_points_max, delta * new_points) # Adjust for time incase someone is using a potato
	
	
	# Point Decay
	if movement_level > 0:
		
		# If we're at the max level then we just begin to decay
		if movement_level == max_level:
			
			decaying = true
			
			# Unless the player is goated
			if score > 4:
				decaying = false
				exponential_decay = 0.0
		
		
		# Otherwise we only decay when velocity is 0 for a set time
		elif score_sample.get_average() <= 0.8 and MOMENTUM_TIMER.is_stopped():
			
			# Start timer
			MOMENTUM_TIMER.start()
			
		# If we start moving then we stop the timer
		elif score_sample.get_average() > 0.8 and not MOMENTUM_TIMER.is_stopped():
			MOMENTUM_TIMER.stop()
			
			# Reset the decay rate once the player starts moving again
			decaying = false
			exponential_decay = 0.0
			
			
		
		
		
		# Actual Decay happens here
		if decaying:
			
			# Exonential Decay Rate
			exponential_decay += glow_decay_rate * 0.025
			
			glow_points = move_toward(glow_points, 0, delta * exponential_decay)
			
			# If the number of points is 0 then we demote
			if round(glow_points) == 0:
				demote()
					
		
		
			
	# Upgrading is the glow up is pressed and score is peaked
	if movement_level <= max_level:
		if round(glow_points) >= 100 and (Input.is_action_just_pressed("Glow_Up") or auto_glow):
			promote()

	# If Glow down is pressed and we're not at the bottom
	if movement_level > 0 and Input.is_action_just_pressed("Glow_Down"):
		demote()		
	
	# Update our meter
	emit_signal("glow_meter_changed", glow_points)
	


# Returns the current speed normalized to "expected" max speeds.
func calc_speed() -> float:
	
	
	
	# If we're walljumping just give full points
	if PLAYER.wallJumping and (PLAYER.current_wj == PLAYER.WALLJUMPS.UPWARD or PLAYER.current_wj == PLAYER.WALLJUMPS.DOWNWARD):
		return 1.0
	
	var new_speed: float = 0.0
	new_speed = abs(PLAYER.velocity.x)
	
	if PLAYER.is_on_floor():
		return new_speed / PLAYER.air_speed
	else:
		return new_speed / PLAYER.speed
	
# This is its own function so it can easily be changed
func calc_score():
	
	
	var speed = calc_speed()
	
	
	var spd_score: float = speed
	
	# If the player is goated give them lotsa points
	if spd_score > 1:
		var surplus: float = speed - 1
		surplus *= surplus_multiplier
		spd_score = 1 + surplus
	
	
	return spd_score

# A public facing method that can be called by other scripts (ex, collectibles) in order to increase
# 	Player's momentum value
func add_score(amount: float) -> void:
	glow_points += amount

func reset_glow():
	
	glow_points = 0
	
	change_state(0) 
		
	# Turn off Aura 
	if movement_level != max_level:
		glow_aura.emitting = false
	

# How we should be accessing change_state() 99% of the time unless in debug
# Returns whether or not we promoted
func promote(starting_points: int = 20) -> bool:

	emit_signal("glow_promote")

	if movement_level < max_level:
		
		print("Glow Boost ", PLAYER.movement_data.GLOW_UPGRADE_BOOST)
		PLAYER.give_boost(PLAYER.movement_data.GLOW_UPGRADE_BOOST)
		
		change_state(movement_level + 1)
		
		# Setup new points
		if movement_level != max_level:
			glow_points = starting_points
		
		
		promotion_fx.emitting = true
		
		return true
		
	# Just use the boost and consume points
	else:
		print("Glow Boost ", PLAYER.movement_data.GLOW_UPGRADE_BOOST)
		PLAYER.give_boost(PLAYER.movement_data.GLOW_UPGRADE_BOOST)
		glow_points = 10
		return false

# How we should be accessing change_state() 99% of the time unless debug mode
func demote() -> bool:
	if movement_level > 0:
		
		change_state(movement_level - 1)
		
		# Reset points and reset decay
		glow_points = 20
		exponential_decay = 0
			
		return true
	return false

# Recalculating variables changing state
# This is a big weird but by doing it like this it enables us to jump around levels
# In debug or just whatever
func change_state(level: int):
	
	# This should only be called when im debugging :3
	if level == movement_level:
		# For when im debugging and change a parameter and want to recalculate the new properties
		PLAYER.calculate_properties()
		return
	
	movement_level = level
	
	_logger.info("Glow Manager - In Level: " + str(movement_level))

	# Ok set the new movement level
	PLAYER.movement_data = PLAYER.movement_states[movement_level]
	
	# Big ass math moment
	PLAYER.calculate_properties()
	
	glow_grow_rate = PLAYER.movement_data.GLOW_GROWTH_RATE
	glow_decay_rate = PLAYER.movement_data.GLOW_DECAY_RATE
	surplus_multiplier = PLAYER.movement_data.SURPLUS_MULTIPLIER
	
	# Toggle Aura
	if movement_level == max_level:
		glow_aura.emitting = true
	else:
		glow_aura.emitting = false
	
	
# Timer is started when we stop moving, if we start moving again it is stopped again
func _on_momentum_time_timeout():
	
		
		
	# Start decaying our points
	decaying = true
