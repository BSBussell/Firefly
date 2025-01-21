class_name Glow_Manager
extends Node

## The sample size for calculating the score average
@export var SPEED_SAMPLE_SIZE: int = 5

@export var GLOW_PARTICLES: CPUParticles2D

## How often we pool speed for a new average
@export var SPEED_POLL_RATE: float = 0.2

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

# Particles UI
var particle_ui: UiComponent = null


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

	# Initialize our sample array
	score_sample = SampleArray.new(SPEED_SAMPLE_SIZE)
	
	
	var config_changed: Callable = Callable(self, "config_changed")
	_config.connect_to_config_changed(config_changed)
	config_changed.call()
	
	
	var ui_loader: UiLoader = _viewports.ui_viewport_container
	await ui_loader.FinishedLoading
	particle_ui = ui_loader.get_component("StarParticles")
	if particle_ui == null:
		printerr("Glow Manager failed to get Particle UI :<")
	
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	
	# If we haven't enabled glow yet then we don't do anything
	if not GLOW_ENABLED:
		update_meter()
		return
	
	# Always enable glow_point growth
	grow_points(delta)
	
	
	# If we're at the max level and not goated then we just begin to decay
	if movement_level == max_level and score <= 4:
		decay_points(delta)
	
	
	# Otherwise we only decay when the score average is below 1.0
	elif score_sample.get_average() <= 1.0:
		
		decay_points(delta)
		
	if auto_glow and round(glow_points) >= 100 and movement_level < max_level:
		promote()
		
	glow_point_visual()
	update_meter()
	
	
func _input(event: InputEvent) -> void:
	
	var glow_boost: float = PLAYER.movement_data.GLOW_UPGRADE_BOOST
	
	# If we press glow up
	if event.is_action_pressed("Glow_Up"):
		
		# Demote and boost in auto glow mode
		if auto_glow and demote():
			PLAYER.give_boost(glow_boost)
			
			particle_ui.burst(32)
			
		# Otherwise if we have enough points use them to promote
		elif not auto_glow and round(glow_points) >= 100:
			promote()
	
	# If we press glow down
	elif event.is_action_pressed("Glow_Down") and demote():
		
		# If we can demote, demote and give the player a speed boost if they want it
		PLAYER.give_boost(glow_boost)	
		
		particle_ui.burst(32)
		
		
	
	return	
	
func update_meter() -> void:
	# Update our meter
	var glow_meter_percentage: int = floor(glow_points)
	
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
		 
	if particle_ui:
		
		#var speed: float = lerpf(0.1, 0.30, (glow_points/100))
		particle_ui.toggle_burn(movement_level, glow_points)
		


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
	
	if GLOW_ENABLED:
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
		
		change_state(movement_level + 1)
		
		# Setup new points
		if movement_level != max_level:
			glow_points = starting_points
		
		
		promotion_fx.emitting = true
		
		return true
		
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
	
	
func config_changed():   
	auto_glow = _config.get_setting("auto_glow")
