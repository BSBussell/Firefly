class_name PlayerMovementData
extends Resource

@export_category("Movement Properties")
@export_group("Base Properties (TILES PER SECOND)")
@export var MAX_SPEED = 9.375 		# Max Tile per second speed
@export var ACCEL = 18.75 			# In tiles per second squared :3
@export var FRICTION = 31.25 		# 
@export var TURN_FRICTION = 50.0

@export_subgroup("Jump Properties")

@export var MAX_JUMP_HEIGHT: float = 2			# The max height of our jump in tiles because im so silly like that
@export var JUMP_RISE_TIME: float = 0.4			# The time it takes to reach that height
@export var JUMP_FALL_TIME: float = 0.3 		# The time it takes to fall back down


@export_subgroup("Air Movement")
@export var AIR_SPEED = 10 			# The Speed in the air
@export var AIR_ACCEL = 20 			# Ability to change directions in air
@export var AIR_FRICT = 30			# Friction but in the air

# How far you fall after
@export var FASTFALL_MULTIPLIER = 2.5

@export_group("Wall Properties")

@export var WALL_FRICTION_MULTIPLIER = 3.0		# The friction from leaning into a wall
@export var WALL_DRIFT_MULTIPLIER = 10.3		# The change in drift from this

@export_subgroup("Wall Jump Properties")
@export var WALL_JUMP_VECTOR: Vector2 = Vector2(2.0, 3.0)	 	# Approx. How many tiles a wall jump will send the player
@export var UP_WALL_JUMP_VECTOR: Vector2 = Vector2(2.0, 3.0) 	# Approx. How many tiles a Upward wall jump will send the player
@export var DOWN_WALL_JUMP_VECTOR: Vector2 = Vector2(-1.0, 3.0)	# Approx. How many tiles a Downward wall jump will send the player

@export var DISABLE_DRIFT: bool = true
@export var UP_DISABLE_DRIFT: bool = false
@export var DOWN_DISABLE_DRIFT: bool = false


@export_group("Slide Properties")
@export var SLIDE_FRICTION: float = 20		# How sliding effects friction
@export var HILL_SPEED: float = 10		# How sliding down hills effect speed
@export var HILL_ACCEL: float = 35		# How sliding down hills effect accel

@export_group("Visual Properties")
@export var RUN_THRESHOLD = 150
@export var TRAIL_LENGTH: int = 0

@export_group("Threshold")
@export var DOWNGRADE_SCORE: float = 0
@export var UPGRADE_SCORE: float = 0.6
