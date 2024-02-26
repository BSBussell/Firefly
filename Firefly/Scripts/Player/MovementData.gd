class_name PlayerMovementData
extends Resource

@export_category("Movement Properties")
@export_group("Base Properties")
@export var SPEED = 150.0
@export var ACCEL = 300.0
@export var FRICTION = 500.0
@export var TURN_FRICTION = 800.0

@export_subgroup("Aerial Properties")
# The Vertical Speed of the Jump (Every fifty is a block
@export var JUMP_VELOCITY = -275.0

# The max height of our jump
@export var MAX_JUMP_HEIGHT: float = 2

# The time it takes to reach that height
@export var JUMP_RISE_TIME: float = 0.4

# The time it takes to fall back down
@export var JUMP_FALL_TIME: float = 0.3


# Friction but in the air
@export var AIR_RESISTANCE = 0.9
# Ability to change directions in air (1 is same as grounded, 10 is very little) 
@export var AIR_DRIFT_MULTIPLIER = 1.15
# How far you fall after
@export var FASTFALL_MULTIPLIER = 2.5

@export_group("Wall Properties")
# The friction from leaning into a wall
@export var WALL_FRICTION_MULTIPLIER = 3.0
# The change in drift from this
@export var WALL_DRIFT_MULTIPLIER = 10.3

@export_subgroup("Wall Jump Properties")
@export var NEUTRAL_WJ_VECTOR = Vector2(8.0, 0.9) # The vector an neutral wall jump will launch at
@export var AWAY_WJ_VECTOR = Vector2(20, 0.8)		# The vector an away wall jump will launch at
@export var DISABLE_DRIFT: bool = true

@export_subgroup("Animation Properties")
@export var RUN_THRESHOLD = 150
