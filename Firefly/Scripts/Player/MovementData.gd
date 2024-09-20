class_name PlayerMovementData
extends Resource

@export_category("Movement Properties")
@export_group("Base Properties (TILES PER SECOND)")
## Max Tile per second speed
@export var MAX_SPEED: float = 9.375 	
## The time it takes to reach that speed	
@export var TIME_TO_ACCEL: float = 0.5
# In terms of how far the player will slide without input
@export var FRICTION: float = 31.25
## TODO: Use this	
@export var TURN_FRICTION: float = 50.0
# The speed at which the players speed will decrease when above max speed
@export var SPEED_REDUCTION: float = 400	

@export_subgroup("Jump Properties")
## The max height of our jump in tiles
@export var MAX_JUMP_HEIGHT: float = 2			
## The time it takes to reach that height in seconds
@export var JUMP_RISE_TIME: float = 0.4		
## The time it takes to fall back down	
@export var JUMP_FALL_TIME: float = 0.3 	
## The horizontal velocity added on jumping
@export var JUMP_HORIZ_BOOST: float = 30		


@export_subgroup("Air Movement")
## Air speed in terms of tiles per second
@export var AIR_SPEED: float = 10 		
## The time it takes to reach that speed	
@export var AIR_TIME_TO_ACCEL: float = 20 		
## The time it takes to slow down
@export var AIR_FRICT: float = 30
## The max speed the player can fall
@export var MAX_FALL_SPEED: float = 600
## The max speed we reach in fast falling
@export var MAX_FF_SPEED: float = 650
## The rate of deceleration when above max speed
@export var AIR_SPEED_RECUTION: float = 120.0		
## How far you fall after fastfalling
@export var FASTFALL_MULTIPLIER: float = 2.5

@export_group("Wall Properties")
## The friction from leaning into a wall
@export var WALL_FRICTION_MULTIPLIER: float = 3.0
## How difficult it is to pull away from a wall
@export var WALL_DRIFT_MULTIPLIER: float = 10.3		



@export_group("Wall Jump Properties")
@export_subgroup("Default Wall Jump")
## Approx. How many tiles a wall jump will send the player
@export var WALL_JUMP_VECTOR: Vector2 = Vector2(2.0, 3.0)	 
## Whether or not the player can drift after a wall jump	
@export var DISABLE_DRIFT: bool = true
## The time it takes to reach the peak of the wall jump
@export var WJ_RISE_TIME: float = 0.25
## How much player velocity is carried over from the wall jump
@export var WJ_VELOCITY_MULTI: float = 0.0

@export_subgroup("UP Wall Jump")
## Approx. How many tiles a Upward wall jump will send the player
@export var UP_WALL_JUMP_VECTOR: Vector2 = Vector2(2.0, 3.0)
## Whether or not the player can drift after a wall jump
@export var UP_DISABLE_DRIFT: bool = false
## The time it takes to reach the peak of the wall jump
@export var UP_WJ_RISE_TIME: float = 0.25
## How much player velocity is carried over from the wall jump
@export var UP_VELOCITY_MULTI: float = 0.0
## How much the player's drift in the direction of the wall is multiplied by. Helps the player to chain wall jumps
@export var UP_AIR_DRIFT_MULTI: float = 2.0

@export_subgroup("DOWN Wall Jump")
## Approx. How many tiles a Downward wall jump will send the player
@export var DOWN_WALL_JUMP_VECTOR: Vector2 = Vector2(-1.0, 3.0)
## Whether or not the player can drift after a wall jump
@export var DOWN_DISABLE_DRIFT: bool = false
## How much player velocity is carried over from the wall jump
@export var DOWN_VELOCITY_MULTI: float = 0.0



@export_group("Slide Properties")
## How far the player will slide forward from max run speed.
@export var SLIDE_DISTANCE: float = 4
## How far the player will slide forward when above max run speed.
@export var MAX_SLIDE_DISTANCE: float = 4
## How fast the player slides downhills, in terms of tiles per second
@export var HILL_SPEED: float = 10
## How long it takes to reach that speed
@export var HILL_TIME_TO_ACCEL: float = 1.2
## Change in speed when stuck in a tunnel
@export var TUNNEL_JUMP_ACCEL: float = 0.14

@export_subgroup("Boost Jump")
## How much the player's jump height is multiplied by when they perform a boost jump
@export var BOOST_JUMP_HEIGHT_MULTI: float = 1.0
## How much horizontal speed is added to the player when they perform a boost jump
@export var BOOST_JUMP_HBOOST: float = 100.0
## What percentage of the max speed the player must be at to perform a boost jump
@export var BOOST_JUMP_THRES: float = 30.0
## When the player is reversing their direction with a boost jump, their speed is multiplied by this.
@export var BJ_REVERSE_MULTIPLIER: float = 0.0



@export_group("Assists")
## How long after leaving the ground the player can still jump
@export var COYOTE_TIME: float = 0.1
## How early in seconds the player can buffer a jump
@export var JUMP_BUFFER: float = 0.125



@export_group("Visual Properties")
## At which speed in TPS the run animation will start
@export var RUN_THRESHOLD: float = 8
## How Long the player's trail is(measured in points, so it will increase with speed)
@export var TRAIL_LENGTH: int = 0
## How bright the player's spotlight is
@export var BRIGHTNESS: float = 0.8
## How much we modulate the player's color by
@export var GLOW: Color = Color(1.0, 1.0, 1.0)
## Wing length
@export var WING_LENGTH: float = 10


@export_group("Glow Meter Properties")
## How Quickly the Glow Meter will fill
@export var GLOW_GROWTH_RATE: float = 5
## How Quickly the Glow Meter will decay
@export var GLOW_DECAY_RATE: float = 3
## When the normalized speed is > 1 we multiplier the surplus by this
@export var SURPLUS_MULTIPLIER: float = 2.0
## Velocity Boost gained from upgrading
@export var GLOW_UPGRADE_BOOST: float = 100.0
## How long we wait before Glow starts to decay
@export var STRICTNESS: float = 3.0
