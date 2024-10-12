extends VBoxContainer
class_name SaveContainer

var FILE_UI: PackedScene = preload("res://Scenes/UI_Elements/File_Select/save_file.tscn")

@onready var animation_player = $"../../../../AnimationPlayer"

# Called when the node enters the scene tree for the first time.
func _ready():
	
	var save_files: PackedStringArray = _persist.get_saves()
		
	# Display all the files
	for file in save_files:
		print(file)
		var new_save_file: FILE_UI = FILE_UI.instantiate()
		add_child(new_save_file)
		new_save_file.set_file(file)
	
	# Adding in the mandatory new file select
	var new_file: FILE_UI = FILE_UI.instantiate()
	add_child(new_file)
	new_file.set_new()
	
	# Display a minimum of 3 files
	while get_child_count() < 3:
		var new_padding: FILE_UI = FILE_UI.instantiate()
		add_child(new_padding)
		new_padding.set_new()
		
	# Update everythings focus neighbor
	update_focus_neighbors()
		
	
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func start_game(path: String):
	animation_player.play("start_game")
	await animation_player.animation_finished
	_loader.load_level(path)	


func update_focus_neighbors():
	
	var prev: Control
	for control: Control in get_children():
		
		
		if prev:
			prev.focus_neighbor_bottom = control.get_path()
			control.focus_neighbor_top = prev.get_path()
		
		prev = control
		

func _on_child_exiting_tree(node):
	
	
	if _loader.loading:
		return
		
	var new_padding: FILE_UI
	if get_child_count()-1 < 3:
		new_padding = FILE_UI.instantiate()
		add_child.call_deferred(new_padding)
		
		new_padding.set_new()
	
	# If we've created a thing wait til its all updated before continuing
	if new_padding:
		await new_padding.ready
		
	update_focus_neighbors()	
	get_child(0).grab_focus()
	
	
	#var file_ui: FILE_UI = node as FILE_UI
	#if file_ui:
		#if not file_ui.new_file:
