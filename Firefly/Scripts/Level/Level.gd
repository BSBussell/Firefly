extends Node
class_name Level

## The Active Player for the Level
@export_category("Components")
@export var PLAYER: Flyph

## The Jars Parent
@export var jar_manager: JarManager

## The Gem's Parent
@export var gem_manager: GemManager

@export_category("Settings")

## Do we load a pause menu
@export var Can_Pause: bool = true


func setup_components() -> void:
	# Register Global Components
	
	if PLAYER:
		_globals.ACTIVE_PLAYER = PLAYER
		player_startup_logic()
		
	if jar_manager:
		_globals.JAR_MANAGER = jar_manager
		jars_startup_logic()
	
	if gem_manager:
		_globals.GEM_MANAGER = gem_manager
		gem_startup_logic()

	

	
# Called when the node enters the scene tree for the first time.
func _ready():
	
	# Setup the available/assigned components
	setup_components()
	
	# Calls the level specific ready
	local_ready()

## Overwrite for level specific ready
func local_ready():
	pass

## Overwrite with any changes needed for player
func player_startup_logic() -> void:
	pass	
	
## Overwrite with any things we want to do with jars
func jars_startup_logic() -> void:
	pass
	
## Overwrite with any things we want to do with gems
func gem_startup_logic() -> void:
	pass
