extends VBoxContainer
class_name SaveContainer

var FILE_UI: PackedScene = preload("res://Scenes/UI_Elements/File_Select/save_file.tscn")

@onready var animation_player = $"../../../../AnimationPlayer"

# Called when the node enters the scene tree for the first time.
func _ready():
	
	var save_files: PackedStringArray = _persist.get_saves()
	
	var prev: Control = null
	
	# Display all the files
	for file in save_files:
		print(file)
		var new_save_file: FILE_UI = FILE_UI.instantiate()
		add_child(new_save_file)
		new_save_file.set_file(file)
		
		# Set focus neighbor
		if prev:
			prev.focus_neighbor_bottom = new_save_file.get_path()
			new_save_file.focus_neighbor_top = prev.get_path()
			
		prev = new_save_file
	
	
	# Adding in the mandatory new file select
	var new_file: FILE_UI = FILE_UI.instantiate()
	add_child(new_file)
	new_file.set_new()
	
	# Set Focus Neighbor
	if prev:
		prev.focus_neighbor_bottom = new_file.get_path()
		new_file.focus_neighbor_top = prev.get_path()
		
	prev = new_file
	
	# Display a minimum of 3 files
	while get_child_count() < 3:
		var new_padding: FILE_UI = FILE_UI.instantiate()
		add_child(new_padding)
		new_padding.set_new()
		
		# set Focus Neighbor
		if prev:
			prev.focus_neighbor_bottom = new_padding.get_path()
			new_padding.focus_neighbor_top = prev.get_path()
			
		prev = new_padding
		
	get_child(0).grab_focus()
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func start_game(path: String):
	animation_player.play("start_game")
	await animation_player.animation_finished
	_loader.load_level(path)	


func _on_child_exiting_tree(node):
	
	if get_child_count()-1 < 3:
		var new_padding: FILE_UI = FILE_UI.instantiate()
		add_child.call_deferred(new_padding)
		new_padding.set_new()
	
	#var file_ui: FILE_UI = node as FILE_UI
	#if file_ui:
		#if not file_ui.new_file:
