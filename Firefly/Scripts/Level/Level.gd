extends Node
class_name Level

enum WIN_CON {
	JARS,
	FUNCTION
}

## Signal Emitted when the player "Wins"
signal Win()

## Signal Emitted to have the player Change Level
signal ChangeLevel(path: String)

@export_category("Title")
@export var Text: String = "- Debug -"

## The Active Player for the Level
@export_category("Components")
@export var PLAYER: Flyph

## The Jars Parent
@export var jar_manager: JarManager

## The Gem's Parent
@export var gem_manager: GemManager

## Each Level Should Have a Unique ID, plz assign
@export var id: int

@export_category("Settings")

## Do we load a pause menu
@export var Can_Pause: bool = true

## What shows us the "Result Screen"
@export var win_condition: WIN_CON = WIN_CON.JARS

var level_loader: LevelLoader = null
var ui_loader: UiLoader = null

var spawn_point: SpawnPoints = null
var spawn_point_id: String = ""

## Used by the loaders to pass themself to the level
func connect_level_loader(ll: LevelLoader) -> void:
	level_loader = ll
	

func set_spawn_id(id: String) -> void:
	spawn_point_id = id

func connect_ui_loader(ui: UiLoader) -> void:
	ui_loader = ui

func setup_components() -> void:
	# Register Global Components
	
	if PLAYER:
		_globals.ACTIVE_PLAYER = PLAYER
		player_startup_logic()
		
		# Check if any spawn points in the scene match the id
		var spawnpoints = []
		spawnpoints = get_tree().get_nodes_in_group("SpawnPoint")
		for point: SpawnPoints in spawnpoints:
			if point.id == spawn_point_id:
				PLAYER.global_position = point.global_position
				PLAYER.set_respawn_point(point.global_position)
				
				spawn_point = point
				break
		
		PLAYER.connect_to_death(Callable(self, "on_death"))
		
		
	else:
		_globals.ACTIVE_PLAYER = null
		
	if jar_manager:
		_globals.JAR_MANAGER = jar_manager
		jars_startup_logic()
		
		# If our win condition is "jars" then
		# Emit the win signal on all jars found
		if win_condition == WIN_CON.JARS:
			var win_function: Callable = Callable(self, "emit_win_signal")
			jar_manager.connect_jar_listener(win_function)
	
	else:
		_globals.JAR_MANAGER = null
	
	if gem_manager:
		_globals.GEM_MANAGER = gem_manager
		gem_startup_logic()
	else:
		_globals.GEM_MANAGER = null

## Calls the level loader to load a new level
func load_level(path: String, spawn_id: String):
	await _loader.load_level(path, spawn_id)
	
	

## Called within a level to emit the win signal
func emit_win_signal() -> void:
	emit_signal("Win")

##  Used to connect listeners to this signal
func connect_to_win(function: Callable):
	var error = connect("Win", function)
	if error != OK:
		print("Failure Connecting Win Signal: ", error)

	
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

## Function Called on Players Death
func on_death() -> void:
	pass
