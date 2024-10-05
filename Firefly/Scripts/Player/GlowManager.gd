class_name Glow_Manager
extends Node

## The sample size for calculating the score average
@export var SPEED_SAMPLE_SIZE: int = 5

@export var GLOW_PARTICLES: CPUParticles2D

## How often we pool speed for a new average
@export var SPEED_POLL_RATE: float = 0.2
@export var MOMENTUM_TIMER: Timer

@onready var PLAYER: Flyph = $".."


@onready var glow_aura = $"../Particles/GlowAura"
@onready var promotion_fx = $"../Particles/PromotionFx"
@onready var spotlight = $"../Visuals/Spotlight"

signal glow_meter_changed(new_value: float)
signal glow_promote()

# If The player has unlocked glow yet/can glow
var GLOW_ENABLED: bool = false

# Players Movement Level
var movement_level: int = 0
var max_level: int

# The players score
var score: float = 0

# Array of scores
var score_sample: SampleArray

# Timer Specifying how often to poll for speed
var poll_count: float = 0.0

# If promotions/demotions are automated
var auto_glow: bool = false




# The number of points they've gained. If they reach max they can promotion
var glow_points: float = 0
var glow_points_max: float = 100

# The rate that they gain points
var glow_grow_rate: float = 5

# The rate that they lose points
var glow_decay_rate: float = 5

# I hate this
var decaying = false
var exponential_decay: float = 0.0

var surplus_multiplier: float = 3.5


var meter = null


# Used for visuals
var prev_glow_points: float = 0.0




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
	
	# Always enable glow_point growth
	grow_points(delta)
	
	
	# If we're at the max level and not goated then we just begin to decay
	if movement_level == max_level and score <= 4:
		decay_points(delta)
	
	
	# Otherwise we only decay when the score average is below 1.0
	elif score_sample.get_average() <= 1.0:
		
		decay_points(delta)
		
		
	# Upgrading is the glow up is pressed and score is peaked
	auto_glow = _config.get_setting("auto_glow") and movement_level < max_level
	
	
	# If we haven't maxed out yet
	if movement_level <= max_level:
		
		# If we've reached 100 and trigged glow up (either thorugh button or auto glow does it)
		if round(glow_points) >= 100 and (Input.is_action_just_pressed("Glow_Up") or auto_glow):
			promote()

	# If Glow down is pressed and we're not at the bottom
	if movement_level > 0 and Input.is_action_just_pressed("Glow_Down"):
		
		var saved_points: int = glow_points
		
		demote()
		
		# Ok just a little exploit pre-fixing, if the player is below 30% on the score thing,
		# dont enable them to easily get glow again. Just to prevent an "off and on again" meta when low on points
		glow_points = 100 if saved_points > 30 else glow_points
	
	
	glow_point_visual()
	
	# Update our meter
	var glow_meter_percentage: int = glow_points
	
	# In auto glow mode, the meter measures how close to max speed we are
	if _config.get_setting("auto_glow"):
		glow_meter_percentage = (glow_points + (100 * movement_level)) / (100 * max_level) * 100
		
		
	# Signal to the meter to change its visual
	emit_signal("glow_meter_changed", glow_meter_percentage)
	

func grow_points(delta: float) -> void:
	
	# Update Scoring information based on movement speed, etc.
	score = calc_score()
	
	# Update Average
	if poll_count >= SPEED_POLL_RATE:
		score_sample.add_element(score)
		poll_count = 0
		
	poll_count += delta
	
	var new_points = score * glow_grow_rate
	
	# Add score to points, score only goes up if we're at max level
	glow_points = move_toward(glow_points, glow_points_max, delta * new_points) # Adjust for time incase someone is using a potato
	

func decay_points(delta: float) -> void:
	
	# Exonential Decay Rate
	exponential_decay = glow_decay_rate
	
	# Decrease the glow points
	glow_points = move_toward(glow_points, 0, delta * exponential_decay)
	
	# If the number of points is 0 then we demote
	if round(glow_points) == 0 and abs(PLAYER.velocity.x) <= 20:
		demote()


func glow_point_visual() -> void:
	
	
	## GLOW PARTICLES
	# Base form just use the speed average to give visuals
	var base_speed: bool = movement_level == 0 and score_sample.get_pop() > 1.0
	
	# Otherforms, check if the number of glow points is increasing from the prev
	var point_growth: bool = movement_level > 0 and (prev_glow_points < glow_points or glow_points == glow_points_max)
	
	if base_speed or point_growth:
		
		GLOW_PARTICLES.emitting = true
		GLOW_PARTICLES.direction.x = 1 if (PLAYER.animation.flip_h) else -1
			
	else:
		
		GLOW_PARTICLES.emitting = false
	
	prev_glow_points = glow_points
	
	
	## FLICKERING
	# If we are at risk of demotion
	if glow_points <= 20 and movement_level > 0:
	
		if not spotlight.flickering:
			spotlight.set_flicker(PLAYER.movement_data.BRIGHTNESS, PLAYER.movement_data.BRIGHTNESS - 0.3, 0.09)
	
	else:
		if spotlight.flickering:
			spotlight.set_brightness(PLAYER.movement_data.BRIGHTNESS)
	
	## If we can power up, emit the "Glow Aura"
	if glow_points == 100:
		glow_aura.emitting = true
	elif movement_level != max_level:
		glow_aura.emitting = false


# Returns the current speed normalized to "expected" max speeds.
func calc_speed() -> float:
	
	var new_speed: float = 0.0
	new_speed = abs(PLAYER.velocity.x)
	
	if PLAYER.is_on_floor():
		new_speed /= (PLAYER.air_speed * 0.9)
	else:
		new_speed /= (PLAYER.speed * 0.9)
		
	new_speed += (abs(PLAYER.velocity.x) / PLAYER.movement_data.MAX_FF_SPEED) * 0.1
		
	# If we're walljumping just give full points
	if PLAYER.wallJumping or PLAYER.launched:
		new_speed += 0.5
	
	return new_speed
	
# This is its own function so it can easily be changed
func calc_score():
	
	
	var speed = calc_speed()
	
	
	var spd_score: float = speed
	
	# If the player is goated give them lotsa points
	if spd_score > 1:
		var surplus: float = speed - 1
		surplus *= surplus_multiplier
		spd_score = 1 + surplus
	
	
	return max(spd_score-0.25, 0)

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
func promote(starting_points: int = 50) -> bool:

	emit_signal("glow_promote")

	if movement_level < max_level:
		
		PLAYER.give_boost(PLAYER.movement_data.GLOW_UPGRADE_BOOST)
		
		change_state(movement_level + 1)
		
		# Setup new points
		if movement_level != max_level:
			glow_points = starting_points
		
		
		promotion_fx.emitting = true
		
		return true
		
	# Just use the boost and consume points
	else:
		PLAYER.give_boost(PLAYER.movement_data.GLOW_UPGRADE_BOOST)
		glow_points = 10
		return false

# How we should be accessing change_state() 99% of the time unless debug mode
func demote() -> bool:
	if movement_level > 0:
		
		change_state(movement_level - 1)
		
		# Reset points and reset decay
		glow_points = 50
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
