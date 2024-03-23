class_name Glow_Manager
extends Node

@export var MAX_ENTRIES: int = 180
@export var SPEEDOMETER_ENTRIES: int = 120
@export var FF_ENTRIES: int = 10
@export var SLIDE_ENTRIES: int = 10

@onready var PLAYER: Flyph = $".."
@onready var meter = $"../UI_FX/Control/Meter"



# Players Movement Score
var movement_level: int = 0
var max_level: int
var score: float = 0

#var air_speed_buffer: Array = []
#var ground_speed_buffer: Array = []
var slide_buffer: Array = []
#var speedometer_buffer: Array = []
var landings_buffer: Array = [] # I think this one might be stupid ngl

var average_speed: float = 0
var average_ff_landings: float = 0
var average_slides: float = 0
var tmp_modifier: float = 0


var GLOW_ENABLED: bool = true

var glow_points: float = 0
var glow_points_max: float = 100
var glow_grow_rate: float = 5
var glow_decay_rate: float = 5

var decaying = false
var exponential_decay: float = 0.0


# Can be called whenever we want to restart the movement system
func startup():
	
	max_level =  len(PLAYER.movement_states) - 1
	
	glow_grow_rate = PLAYER.movement_data.GLOW_GROWTH_RATE
	glow_decay_rate = PLAYER.movement_data.GLOW_DECAY_RATE
	
	# Setting up our buffers
	#air_speed_buffer.resize(MAX_ENTRIES)
	#ground_speed_buffer.resize(MAX_ENTRIES)
	#landings_buffer.resize(FF_ENTRIES)
	#speedometer_buffer.resize(SPEEDOMETER_ENTRIES)
	#slide_buffer.resize(SLIDE_ENTRIES)

	# Filling them with nothing
	#speedometer_buffer.fill(0)
	#air_speed_buffer.fill(0)
	#ground_speed_buffer.fill(0)
	#landings_buffer.fill(0)
	#slide_buffer.fill(0)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	if not GLOW_ENABLED:
		return
	
	# Update Scoring information based on movement speed, etc.
	var score: float = calc_score() * glow_grow_rate
	
	# Add score to points, score only goes up if we're at max level
	if movement_level != max_level:
		glow_points = move_toward(glow_points, glow_points_max, delta * score)
	
	
	
	
	# If we aren't base 
	if movement_level > 0:
		
		# Begin Decay
		if PLAYER.velocity.x == 0:
			decaying = true
		else:
			decaying = false
			exponential_decay = 0.0
		
		if decaying == true:
			
			exponential_decay += glow_decay_rate * 0.1
			
			glow_points = move_toward(glow_points, 0, delta * exponential_decay)
			if round(glow_points) == 0:
				if demote():
					glow_points = 20
					exponential_decay = 0
	
	# Upgrading is the glow up is pressed and score is peaked
	if movement_level <= max_level:
		if round(glow_points) >= 100 and Input.is_action_just_pressed("Glow_Up"):
			if promote():
				if movement_level != max_level:
					glow_points = 20
	
	# Update our meter
	meter.set_score(glow_points)


# Returns the current speed normalized to "expected" max speeds.
func calc_speed() -> float:
	
	var new_speed: float = 0.0
	
	# If we're walljumping give bonus points :3
	if (PLAYER.current_wj == PLAYER.WALLJUMPS.UPWARD or PLAYER.current_wj == PLAYER.WALLJUMPS.DOWNWARD):
		new_speed = abs(PLAYER.velocity.y) * 3
	else:
		new_speed = abs(PLAYER.velocity.x)
	
	if PLAYER.is_on_floor():
		return new_speed / PLAYER.air_speed
	else:
		return new_speed / PLAYER.speed
	
	
	
# Called each landing, we counts how often we land with a fast fall
# The assumption being that a player fast falling often is moving quickly lol
func update_ff_landings(did_ff_land):
	
	# Don't modify score while glow is disabled
	if not GLOW_ENABLED:
		return
	
	# Add the new fast-fall landing value (1.0 for yes, 0.0 for no) to the buffer and remove the oldest entry
	landings_buffer.pop_front()
	landings_buffer.append(did_ff_land)
	# Update the average fast-fall landings using reduce()
	average_ff_landings = landings_buffer.reduce(func(acc, num): return acc + num) / landings_buffer.size()

# Called on every slide, allows us to count how often the player slides optimally
func update_slides(was_optimal):
	
	# Don't modify score while glow is disabled
	if not GLOW_ENABLED:
		return
	
	slide_buffer.pop_front()
	slide_buffer.append(was_optimal)
	
	average_slides = slide_buffer.reduce(func(acc, num): return acc + num) / slide_buffer.size()

# Updates the score and change states if appropriate
#func update_score():
	#
	#score = calc_score()
	#
	#if GLOW_ENABLED:
		#if score >= PLAYER.movement_data.UPGRADE_SCORE and movement_level != max_level:
			#
			#PLAYER.star.emitting = true
			#change_state(movement_level + 1)
			#
		#elif score <= PLAYER.movement_data.DOWNGRADE_SCORE and movement_level != 0:
			#
			#change_state(movement_level - 1)

# This is its own function so it can easily be changed
func calc_score():
	
	#var ff_score = (0.2 * average_ff_landings)
	#var slide_score = (0.2 * average_slides)
	
	# Speed Score (these numbers are not arbitrary lmao)
	#var air_spd_score = (0.1625 * air_normalized_average_speed)
	#var ground_spd_score = (0.4875 * ground_normalized_average_speed)
	
	# Honestly this is probably a shitty way of doing this lmao
	var speed = calc_speed()
	#var air_score = 0.1625 * speeds["air_score"]
	#var ground_score = 0.4875 * speeds["ground_score"]
	
	
	var spd_score = speed
	
	
	return spd_score + tmp_modifier

# A public facing method that can be called by other scripts (ex, collectibles) in order to increase
# 	Player's momentum value
func add_score(amount: float, weight: float) -> void:
	tmp_modifier += amount
	await get_tree().create_timer(weight).timeout
	tmp_modifier -= amount

func reset_score():
	#
	#speedometer_buffer.fill(0)
	#air_speed_buffer.fill(0)
	#ground_speed_buffer.fill(0)
	landings_buffer.fill(0)
	slide_buffer.fill(0)

# How we should be accessing change_state() 99% of the time unless in debug
# Returns whether or not we promoted
func promote() -> bool:
	if movement_level < max_level:
		change_state(movement_level + 1)
		return true
	return false

# How we should be accessing change_state() 99% of the time unless debug mode
func demote() -> bool:
	if movement_level > 0:
		change_state(movement_level - 1)
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
	
	# Setup Meter
	#if movement_level != max_level:
		#meter.update_range(0, PLAYER.movement_data.UPGRADE_SCORE * 100)
	
	# So if we are the max level then we set the meter to only go down when the players at risk of losing momentum
	#else:
		#meter.update_range(0, PLAYER.movement_data.DOWNGRADE_SCORE * 100)
		
