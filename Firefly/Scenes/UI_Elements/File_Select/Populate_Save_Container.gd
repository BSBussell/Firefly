extends VBoxContainer

var FILE_UI: PackedScene = preload("res://Scenes/UI_Elements/File_Select/save_file.tscn")


# Called when the node enters the scene tree for the first time.
func _ready():
	
	var save_files: PackedStringArray = _persist.get_saves()
	for file in save_files:
		print(file)
		var new_save_file: FILE_UI = FILE_UI.instantiate()
		add_child(new_save_file)
		new_save_file.set_file(file)
		new_save_file.grab_focus()
	
	var new_file: FILE_UI = FILE_UI.instantiate()
	add_child(new_file)
	new_file.set_new()
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
