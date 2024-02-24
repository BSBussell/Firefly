class_name Flyph
extends CharacterBody2D

@export_category("Movement Resource")
@export var base_movement : PlayerMovementData
@export var speed_movement: PlayerMovementData

@export var star: CPUParticles2D
@export var debug_info: Label


@onready var animation = $AnimatedSprite2D
@onready var StateMachine = $StateMachine
@onready var spotlight = $Spotlight
@onready var light_animator = $Spotlight/light_animator
@onready var trail = $Trail


@onready var movement_data = base_movement
@onready var FF_Vel = movement_data.JUMP_VELOCITY / movement_data.FASTFALL_MULTIPLIER

const JUMP_DUST = preload("res://Scenes/Player/particles/jump_dust.tscn")
const LANDING_DUST = preload("res://Scenes/Player/particles/landing_dust.tscn")

enum ANI_STATES { 
	
	CRAWL,
	CROUCH,
	FALLING,
	IDLE,
	JUMP,
	LANDING,
	RUNNING,
	STANDING_UP,	# From Crawl
	WALKING
	
}

var fastFalling = false
var airDriftDisabled = false
var wallJumping = false
var turningAround = false

@onready var cacheAirdrift = movement_data.AIR_DRIFT_MULTIPLIER

var current_animation: ANI_STATES
var prev_animation: ANI_STATES
var restart_animation: bool = false

var vertical_axis = 0
var horizontal_axis = 0


# Players Movement Score
var score = 0

const MAX_ENTRIES = 500

var speed_buffer = []
var landings_buffer = []

var average_speed = 0
var average_ff_landings = 0

var tmp_modifier = 0

# I'm Being really annoying about this btw
func _ready() -> void:
	
	# Setting up our buffers
	speed_buffer.resize(MAX_ENTRIES)
	landings_buffer.resize(MAX_ENTRIES)
	
	speed_buffer.fill(0.5)
	landings_buffer.fill(0.5)


	
	# Initialize the State Machine pass self to it
	StateMachine.init(self)
	
func _unhandled_input(event: InputEvent) -> void:
	
	horizontal_axis = Input.get_axis("Left", "Right")
	vertical_axis = Input.get_axis("Down", "Up")
	
	StateMachine.process_input(event)
	
func _physics_process(delta: float) -> void:
	
	StateMachine.process_physics(delta)
	
	update_speed(abs(velocity.x))
	
func _process(delta: float) -> void:
	
	
	if restart_animation:
		animation.set_frame_and_progress(0,0)
	
	
	# Only update animations if we've changed animations
	if prev_animation != current_animation or restart_animation:
		
		#print("craw: Updating animations")
		#if (current_animation == ANI_STATES.CROUCH):
			#print("crouch animation being updated")
		#elif (current_animation == ANI_STATES.STANDING_UP):
			#print("STANIDNG UP UPDATED")
		#elif (current_animation == ANI_STATES.CRAWL):
			#print("SO IT DOES EXIST!!!")
		update_animations()
		restart_animation = false
		
	prev_animation = current_animation
	
	# Let each component do their frame stuff
	StateMachine.process_frame(delta)

	score = (0.4 * average_ff_landings + 0.6 * average_speed) + tmp_modifier
	debug_info.text = "%.02f" % score
	#print("Average FF: ", average_ff_landings)
	#print("Average Speed: ", average_speed)
	#print("Average Score: ", score)
	

func update_animations():
	
	match current_animation:
		
		# Basic Animations
		ANI_STATES.IDLE:
			animation.play("idle")	
		ANI_STATES.WALKING:
			animation.play("walking")
		ANI_STATES.RUNNING:
			animation.play("running")
		
		# Crouch Animations
		ANI_STATES.CRAWL:
			#print("crawl: played")
			animation.play("crawl")
		ANI_STATES.CROUCH:
			animation.play("crouch")
		ANI_STATES.STANDING_UP:
			animation.play("stand up")
		
		# Air/Jump Animations
		ANI_STATES.JUMP:
			animation.play("jump")
		ANI_STATES.FALLING:
			animation.play("falling")
		ANI_STATES.LANDING:
			animation.play("landing")
		
		
		
		
		
		
		
func _on_animated_sprite_2d_animation_finished():
	
	StateMachine.animation_end()

func update_speed(new_speed):
	
	var percentage_value = new_speed / movement_data.SPEED
	
	# Add the new speed value to the buffer and remove the oldest entry
	speed_buffer.pop_front()
	speed_buffer.append(percentage_value)
	# Update the average speed using reduce()
	average_speed = speed_buffer.reduce(func(acc, num): return acc + num) / speed_buffer.size()

func update_ff_landings(did_ff_land):
	# Add the new fast-fall landing value (1.0 for yes, 0.0 for no) to the buffer and remove the oldest entry
	landings_buffer.pop_front()
	landings_buffer.append(did_ff_land)
	# Update the average fast-fall landings using reduce()
	average_ff_landings = landings_buffer.reduce(func(acc, num): return acc + num) / landings_buffer.size()


func update_score():
	
	score = (0.4 * average_ff_landings + 0.6 * average_speed)
	score += tmp_modifier
	
	if score > 0.6:
		
		
		if movement_data != speed_movement:
			movement_data = speed_movement
			star.emitting = true 
			light_animator.play("turn_up")
			trail.length = 10
	else:
		
		if movement_data != base_movement:
			movement_data = base_movement
			light_animator.play("turn_down")
			trail.length = 0


func _on_momentum_time_timeout():
	update_score()
	
# A public facing method that can be called by other scripts (ex, collectibles) in order to increase
# 	Player's momentum value
func add_momentum(amount: float, weight: float) -> void:
	tmp_modifier += amount
	await get_tree().create_timer(weight).timeout
	tmp_modifier -= amount

