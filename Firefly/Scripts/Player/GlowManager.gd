class_name Glow_Manager
extends Node

@export var MAX_ENTRIES: int = 180
@export var SPEEDOMETER_ENTRIES: int = 120
@export var FF_ENTRIES: int = 10
@export var SLIDE_ENTRIES: int = 10
@export var MOMENTUM_TIMER: Timer

@onready var PLAYER: Flyph = $".."
@onready var meter = $"../UI_FX/Control/Meter"
@onready var stars = $"../UI_FX/Star"
@onready var glow_aura = $"../Particles/GlowAura"



# Players Movement Score
var movement_level: int = 0
var max_level: int
var score: float = 0

var GLOW_ENABLED: bool = true

var glow_points: float = 0
var glow_points_max: float = 100
var glow_grow_rate: float = 5
var glow_decay_rate: float = 5

var decaying = false
var exponential_decay: float = 0.0

var surplus_multiplier: float = 2.0


# Can be called whenever we want to restart the movement system
func startup():
	
	max_level =  len(PLAYER.movement_states) - 1
	
	glow_grow_rate = PLAYER.movement_data.GLOW_GROWTH_RATE
	glow_decay_rate = PLAYER.movement_data.GLOW_DECAY_RATE
	
	MOMENTUM_TIMER.stop()
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	if not GLOW_ENABLED:
		return
	
	# Update Scoring information based on movement speed, etc.
	var score: float = calc_score()
	var new_points = score * glow_grow_rate
	
	# Add score to points, score only goes up if we're at max level
	glow_points = move_toward(glow_points, glow_points_max, delta * new_points) # Adjust for time incase someone is using a potato
	
	
	# Point Decay
	if movement_level > 0:
		
		# If we're at the max level then we just begin to decay
		if movement_level == max_level:
			
			decaying = true
			
			# Unless the player is goated
			if score > 3:
				decaying = false
				exponential_decay = 0.0
		
		# Otherwise we only decay when velocity is 0 for a set time
		elif (PLAYER.velocity.x == 0) and MOMENTUM_TIMER.is_stopped():
			
			# Start timer
			MOMENTUM_TIMER.start()
			
			print("Starting Timer")
		
		# If we start moving then we stop the timer
		elif PLAYER.velocity.x != 0 and not MOMENTUM_TIMER.is_stopped():
			MOMENTUM_TIMER.stop()
			
			# Reset the decay rate once the player starts moving again
			decaying = false
			exponential_decay = 0.0
			
			
		
		
		
		# Actual Decay happens here
		if decaying:
			
			# Exonential Decay Rate
			exponential_decay += glow_decay_rate * 0.1
			
			glow_points = move_toward(glow_points, 0, delta * exponential_decay)
			
			# If the number of points is 0 then we demote
			if round(glow_points) == 0:
				demote()
					
		
		
			
	# Upgrading is the glow up is pressed and score is peaked
	if movement_level <= max_level:
		if round(glow_points) >= 100 and Input.is_action_just_pressed("Glow_Up"):
			promote()
				
	
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
	
# This is its own function so it can easily be changed
func calc_score():
	
	
	var speed = calc_speed()
	
	
	var spd_score: float = speed
	
	# If the player is goated give them lotsa points
	if spd_score > 1:
		var surplus: float = speed - 1
		surplus *= surplus_multiplier
		spd_score = 1 + surplus
		print(surplus)
	
	
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
func promote() -> bool:
	if movement_level < max_level:
		stars.emitting = true
		
		change_state(movement_level + 1)
		
		# Setup new points
		if movement_level != max_level:
			glow_points = 20
		
		return true
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
	
	# If we still aren't moving
	if PLAYER.velocity.x == 0:
		
		print("decaying irl")
		
		# Start decaying our points
		decaying = true
