extends Node


## This is true if we are within the game loop
var ACTIVE_LEVEL: Level

## This holds the active player object
var ACTIVE_PLAYER: Flyph

## This holds the active gem manager object for the current running level
var GEM_MANAGER: GemManager

## The Jar Manager Object for the Current Level
var JAR_MANAGER: JarManager

## The current game render size
var RENDER_SIZE: Vector2 = Vector2(320, 180)


## Guilds a hash based on the objects position and level id.
## Severely imperfect, will address the day a id collision occurs
func gen_id(position: Vector2) -> String:
	
	# Variables that make this jar unique
	var identifiers = [
		position,
		ACTIVE_LEVEL.id
	]
	
	return str(hash(str(identifiers)))
