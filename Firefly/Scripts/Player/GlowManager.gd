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



var air_speed_buffer: Array = []
var ground_speed_buffer: Array = []
var slide_buffer: Array = []
var speedometer_buffer: Array = []
var landings_buffer: Array = [] # I think this one might be stupid ngl

var average_speed: float = 0
var air_normalized_average_speed: float = 0
var ground_normalized_average_speed: float = 0
var average_ff_landings: float = 0
var average_slides: float = 0
var tmp_modifier: float = 0


var GLOW_ENABLED: bool = true


# Can be called whenever we want to restart the movement system
func startup():
	
	max_level =  len(PLAYER.movement_states) - 1
	
	# Setting up our buffers
	air_speed_buffer.resize(MAX_ENTRIES)
	ground_speed_buffer.resize(MAX_ENTRIES)
	landings_buffer.resize(FF_ENTRIES)
	speedometer_buffer.resize(SPEEDOMETER_ENTRIES)
	slide_buffer.resize(SLIDE_ENTRIES)

	# Filling them with nothing
	speedometer_buffer.fill(0)
	air_speed_buffer.fill(0)
	ground_speed_buffer.fill(0)
	landings_buffer.fill(0)
	slide_buffer.fill(0)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	# Update Scoring information based on movement speed, etc.
	update_speed()
	score = calc_score()
	
	
	
	# Update our meter
	meter.set_score(score * 100)
	pass


# Record Current Speed
func update_speed():
	
	var new_speed: float = 0.0
	
	if (PLAYER.current_wj == PLAYER.WALLJUMPS.UPWARD or PLAYER.current_wj == PLAYER.WALLJUMPS.DOWNWARD):
		new_speed = abs(PLAYER.velocity.y) * 3
	else:
		new_speed = abs(PLAYER.velocity.x)
	
	
	
	var air_percentage_value = new_speed / PLAYER.air_speed
	var ground_percentage_value = new_speed / PLAYER.speed
	
	# Add the new speed value to the buffer and remove the oldest entry
	air_speed_buffer.pop_front()
	air_speed_buffer.append(air_percentage_value)
	
	ground_speed_buffer.pop_front()
	ground_speed_buffer.append(ground_percentage_value)
	
	speedometer_buffer.pop_front()
	speedometer_buffer.append(new_speed)
	
	# Update the average speed using reduce()
	air_normalized_average_speed = air_speed_buffer.reduce(func(acc, num): return acc + num) / air_speed_buffer.size()
	ground_normalized_average_speed = ground_speed_buffer.reduce(func(acc, num): return acc + num) / ground_speed_buffer.size()
	average_speed = speedometer_buffer.reduce(func(acc, num): return acc + num) / speedometer_buffer.size()

# Called each landing, we counts how often we land with a fast fall
# The assumption being that a player fast falling often is moving quickly lol
func update_ff_landings(did_ff_land):
	# Add the new fast-fall landing value (1.0 for yes, 0.0 for no) to the buffer and remove the oldest entry
	landings_buffer.pop_front()
	landings_buffer.append(did_ff_land)
	# Update the average fast-fall landings using reduce()
	average_ff_landings = landings_buffer.reduce(func(acc, num): return acc + num) / landings_buffer.size()

# Called on every slide, allows us to count how often the player slides optimally
func update_slides(was_optimal):
	
	slide_buffer.pop_front()
	slide_buffer.append(was_optimal)
	
	average_slides = slide_buffer.reduce(func(acc, num): return acc + num) / slide_buffer.size()

# Updates the score and change states if appropriate
func update_score():
	
	score = calc_score()
	
	if GLOW_ENABLED:
		if score >= PLAYER.movement_data.UPGRADE_SCORE and movement_level != max_level:
			
			PLAYER.star.emitting = true
			change_state(movement_level + 1)
			
		elif score <= PLAYER.movement_data.DOWNGRADE_SCORE and movement_level != 0:
			
			change_state(movement_level - 1)

# This is its own function so it can easily be changed
func calc_score():
	
	var ff_score = (0.2 * average_ff_landings)
	var slide_score = (0.2 * average_slides)
	
	# Speed Score (these numbers are not arbitrary lmao)
	var air_spd_score = (0.1625 * air_normalized_average_speed)
	var ground_spd_score = (0.4875 * ground_normalized_average_speed)
	
	# Honestly this is probably a shitty way of doing this lmao
	
	var spd_score = air_spd_score + ground_spd_score
	
	
	return ff_score + spd_score + slide_score + tmp_modifier

# Timer that determines how often we are checking the score
func _on_momentum_time_timeout():
	update_score()
	
# A public facing method that can be called by other scripts (ex, collectibles) in order to increase
# 	Player's momentum value
func add_score(amount: float, weight: float) -> void:
	tmp_modifier += amount
	await get_tree().create_timer(weight).timeout
	tmp_modifier -= amount

func reset_score():
	
	speedometer_buffer.fill(0)
	air_speed_buffer.fill(0)
	ground_speed_buffer.fill(0)
	landings_buffer.fill(0)
	slide_buffer.fill(0)

# Recalculating variables changing state
# This is a big weird but by doing it like this it enables us to jump around levels
# In debug or just whatever
func change_state(level: int):
	
	# This should only be called when im lazy
	#if level == movement_level:
		#return
	
	movement_level = level
	
	# Ok set the new movement level
	PLAYER.movement_data = PLAYER.movement_states[movement_level]
	
	# Big ass math moment
	PLAYER.calculate_properties()
