extends Node2D

## This is the Gem Manager, it is responsible for keeping up with our gems, spawning them in, and various other tasks
class_name GemManager


var gem_scene: PackedScene = preload("res://Scenes/Collectibles/gem.tscn")
var blue_gem: PackedScene = preload("res://Scenes/Collectibles/blueGem.tscn")

# Create an array of objects type Gem
var gem_array = []

var gems_shown: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():

	# Register all our gems
	for child in get_children():
		var gem = child as Gem
		if gem:
			gem_array.append(gem)

## Spawns a gem at the provided GLOBAL COORDINATES, returns this gem for customization
func spawn_gem(pos: Vector2) -> Gem:
	
	var new_gem: Gem
	new_gem = gem_scene.instantiate()
	#add_child(new_gem)
	call_deferred("add_child", new_gem)
	gem_array.append(new_gem)
	new_gem.global_position = pos
	
	await new_gem.ready
	return new_gem

func spawn_blue_gem(pos: Vector2) -> Gem:
	
	var new_gem: Gem
	new_gem = blue_gem.instantiate()
	#add_child(new_gem)
	call_deferred("add_child", new_gem)
	gem_array.append(new_gem)
	new_gem.global_position = pos
	
	await new_gem.ready
	return new_gem


## Respawns every gem
func respawn_all():
	for gem in gem_array:
		gem.respawn()

## Makes our gems visible
func show_gems():
	if gems_shown:
		return

	for gem in gem_array:
		gem.activate()

	gems_shown = true

## Makes our gems invisible
func hide_gems():

	for gem in gem_array:
		gem.deactivate()

	gems_shown = false
