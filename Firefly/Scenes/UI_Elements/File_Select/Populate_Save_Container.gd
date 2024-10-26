extends VBoxContainer
class_name SaveContainer

var FILE_UI: PackedScene = preload("res://Scenes/UI_Elements/File_Select/save_file.tscn")


@onready var scroll_container = $"../.."
@onready var animation_player = $"../../../../AnimationPlayer"

# Called when the node enters the scene tree for the first time.
func _ready():
	
	var save_files: PackedStringArray = _persist.get_saves()
		
	# Display all the files
	for file in save_files:
		print(file)
		var new_save_file: FileUI = FILE_UI.instantiate()
		add_child(new_save_file)
		new_save_file.set_file(file)
	
	# Adding in the mandatory new file select
	var new_file: FileUI = FILE_UI.instantiate()
	add_child(new_file)
	new_file.set_new()
	
	# Display a minimum of 3 files
	while get_child_count() < 3:
		var new_padding: FileUI = FILE_UI.instantiate()
		add_child(new_padding)
		new_padding.set_new()
		
	# Update everythings focus neighbor
	update_focus_neighbors()
	
	#await get_tree().create_timer(1.0).timeout
	#scroll_container.set_deferred("scroll_vertical", 0)
	
	
		
	
	


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
	
	if prev:
		await prev.ready
		scroll_container.scroll_vertical = 0
		#scroll_container.set_deferred("scroll_vertical", 0)
		

func _on_child_exiting_tree(node):
	
	
	# If children are exiting tree because we are loading a new scene let it happen
	if _loader.loading:
		return
	
	## Get the element above the exiting node
	var above_element: Control
	var control_element: Control = node as Control
	if control_element:
		above_element = get_node(control_element.focus_neighbor_top)
	
	
	# Ensure there are a minimum of 3 files on screen
	var new_padding: FileUI = null
	if get_child_count()-1 < 3:
		new_padding = FILE_UI.instantiate()
		add_child.call_deferred(new_padding)
		
		new_padding.set_new()
	
	# If we've created a thing wait til its all updated before continuing
	if new_padding:
		await new_padding.ready
		
	# Wait for the node to exit the tree, if its valid
	if is_instance_valid(node):
		await node.tree_exited	
		
	# Update the linked focus's
	update_focus_neighbors()
	
	# Set Focus 
	if above_element:
		above_element.grab_focus()
	else:
		get_child(0).grab_focus()
