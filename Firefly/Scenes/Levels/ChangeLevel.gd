extends Area2D

@export var new_level: PackedScene

@onready var world: Level = $"../.."


	


func _on_area_entered(area):
	var new_level_path = new_level.get_path()
	print(new_level_path)
	world.load_level(new_level_path)
