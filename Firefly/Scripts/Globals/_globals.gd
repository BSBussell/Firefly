extends Node

## This is true if we are within the game loop
var ACTIVE_LEVEL: bool

## This holds the active player object
var ACTIVE_PLAYER: Flyph

# This holds the active gem manager object for the current running level
# var ACTIVE_CHECKPOINT_MANAGER: GemManager
var GEM_MANAGER: GemManager

var RENDER_SIZE: Vector2 = Vector2(320, 180)
