extends Area2D

#@export var new_level: PackedScene
@export_file("*.tscn") var new_level: String
@export var spawn_id: String

@onready var world: Level = $"../.."


var execute_once: bool = false


func _on_area_entered(area):
	
	
	
	if not new_level:
		print("uh")
		return
	var new_level_path = new_level
	print(new_level_path)
	
	if not execute_once:
		execute_once = true
		world.load_level(new_level_path, spawn_id)
