extends Node2D

## This is the Gem Manager, it is responsible for keeping up with our gems, spawning them in, and various other tasks
class_name GemManager


# Create an array of objects type Gem
var gem_array = []

# Called when the node enters the scene tree for the first time.
func _ready():

	# Register all our gems
	for child in get_children():
		var gem = child as Gem
		if gem:
			gem_array.append(gem)


## Respawns every gem
func respawn_all():
	for gem in gem_array:
		gem.respawn()

## Makes our gems visible
func show_gems():
	for gem in gem_array:
		gem.activate()

## Makes our gems invisible
func hide_gems():
	for gem in gem_array:
		gem.deactivate()
