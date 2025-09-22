extends Node2D
class_name Cutscene

# Identification for save/load
@export var cutscene_id: String = "!!!CHANGE ME!!!"

# Level reference to reach UI components (Dialogue)
@export var level: Level

# Cutscene trigger area
@export var trigger_area: Area2D

# Cutscene animation player
@export var anim_player: AnimationPlayer

# Cutscene animation name
@export var cutscene_animation_name: String

# Defaults to make sequencing easy in editor
@export_group("Sequence Defaults")
@export_file("*.json") var default_dialogue_path: String
@export var default_next_animation: StringName = &""

# 
var cutscene_over: bool = false

var player: Flyph = null
var dialogue_ui: DialogueUiComponent = null

# Persistence: has this cutscene been played?
var played: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():

	# Register persistence early so loader can deliver saved state
	_register_persistence()

	await _loader.finished_loading
	
	if is_instance_valid(trigger_area):
		trigger_area.body_entered.connect(_on_body_entered)

	# Try to get the Dialogue UI from the level if provided
	if level:
		dialogue_ui = level.get_ui_component("DialogueUiComponent") as DialogueUiComponent
		if dialogue_ui == null:
			push_warning("Cutscene.gd: DialogueUiComponent not found via Level. Dialog features disabled.")

	# Stop processing until cutscene starts
	set_process(false)

	# If this cutscene was already played, ensure trigger is disabled
	if played and is_instance_valid(trigger_area):
		trigger_area.set_deferred("monitoring", false)
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	# If player is null return with error
	if player == null:
		push_error("Cutscene.gd: Player is null")
		return

	# If player is on ground, play animation
	if player.is_on_floor():
		anim_player.play(cutscene_animation_name)
		set_process(false)


func _on_body_entered(body: Node) -> void:

	# Ignore if already played
	if played:
		return

	# Check body type
	var local_player: Flyph = body as Flyph
	if local_player == null:
		return

	if local_player.is_actor:
		return
		
	player = local_player

	# Else set process to true
	set_process(true)

	# Disable player control
	player.is_actor = true
	player.lock_h_dir(0, 0.1)

# Called by animation player at end of cutscene
func set_cutscene_over() -> void:
	cutscene_over = true
	played = true
	_persist.save_values()

	# Re-enable player control
	if is_instance_valid(player):
		# Stop any residual input/motion the cutscene may have applied
		player.lock_h_dir(0, 0.15, true)
		player.horizontal_axis = 0
		player.velocity.x = 0
		player.lock_dir = false
		player.hold_dir = 0
		player.soft_lock = false
		# Return control to the player
		player.is_actor = false
		

	# Disable area so cutscene doesn't trigger again
	if is_instance_valid(trigger_area):
		trigger_area.set_deferred("monitoring", false)

	# Stop the animation to avoid tracks lingering
	if is_instance_valid(anim_player):
		anim_player.stop()

	# Stop processing so this cutscene doesn't try to restart
	set_process(false)


# ——— Persistence ———

func _register_persistence() -> void:
	# Save and load functions for this cutscene
	var save_callable: Callable = Callable(self, "_save_cutscene_state")
	var load_callable: Callable = Callable(self, "_load_cutscene_state")
	_persist.register_persistent_class(cutscene_id, save_callable, load_callable)

func _save_cutscene_state() -> Dictionary:
	return {
		"played": played,
		"cutscene_id": cutscene_id
	}

func _load_cutscene_state(save_data: Dictionary) -> void:
	if save_data.has("played"):
		played = save_data["played"]
	# If played, proactively disable trigger so it won't fire
	if played and is_instance_valid(trigger_area):
		trigger_area.set_deferred("monitoring", false)

func _exit_tree() -> void:
	# Cleanly unregister to avoid stale callables
	_persist.unregister_persistent_class(cutscene_id)


# Utility: load a dialogue JSON file into a Dictionary
func _load_dialogue_file(path: String) -> Dictionary:
	if path == null or path == "":
		return {}
	var data: Dictionary = {}
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		var parsed = JSON.parse_string(json_string)
		if typeof(parsed) == TYPE_DICTIONARY:
			data = parsed
		else:
			printerr("Cutscene.gd: Could not parse JSON at " + str(path))
	else:
		printerr("Cutscene.gd: Could not open dialogue file: " + str(path))
	return data


# Public API: queue a dialogue, then optionally play an animation after it finishes.
# If `next_animation` is empty, the cutscene ends after the dialogue.
# If `dialogue_path` is empty, falls back to `default_dialogue_path`.
func queue_dialog_then_animation(dialogue_path: String = "", next_animation: String = "") -> void:
	if dialogue_ui == null:
		push_error("Cutscene.gd: DialogueUiComponent not available. Did you assign `level`?")
		return

	var use_path = dialogue_path if dialogue_path != "" else default_dialogue_path
	var data = _load_dialogue_file(use_path)
	if data.is_empty():
		push_error("Cutscene.gd: Dialogue data empty for path: " + str(use_path))
		return

	# Show dialogue and wait for UI to close
	dialogue_ui.initiate_dialogue(data, false)
	await dialogue_ui.dialogue_closed

	# Optionally play an animation after dialogue
	if next_animation != null and next_animation != "":
		if anim_player:
			anim_player.play(next_animation)
			# Let the animation's own tracks decide when to end (or fall back after it finishes)
			await anim_player.animation_finished
			# If the animation did not explicitly end the cutscene, do it here
			if not cutscene_over:
				set_cutscene_over()
	else:
		# No further animation; end cutscene now
		set_cutscene_over()


# Editor-friendly variant: pick a DialogueArea2D node via NodePath in AnimationPlayer
func queue_dialog_from_area_path(area_path: NodePath, next_animation: String = "") -> void:
	var area: DialogueArea2D = get_node_or_null(area_path)
	if area == null:
		push_error("Cutscene.gd: DialogueArea2D not found at path: " + str(area_path))
		return
	await queue_dialog_then_animation(area.dialogue_file, next_animation)


# Editor-friendly: pass any Resource, use its resource_path to read JSON
func queue_dialog_from_resource(res: Resource, next_animation: String = "") -> void:
	if res == null or String(res.resource_path) == "":
		push_error("Cutscene.gd: Resource has no external file path.")
		return

	var file_path = res.resource_path
	var text = FileAccess.get_file_as_string(file_path)
	var data = JSON.parse_string(text)
	if typeof(data) != TYPE_DICTIONARY:
		push_error("Cutscene.gd: JSON file didn't parse into a Dictionary: " + str(file_path))
		return

	if dialogue_ui == null:
		push_error("Cutscene.gd: DialogueUiComponent not available. Did you assign `level`?")
		return

	# Show dialogue and wait for UI to close
	dialogue_ui.initiate_dialogue(data, false)
	await dialogue_ui.dialogue_closed

	# Optionally play an animation after dialogue
	if next_animation != null and next_animation != "":
		if anim_player:
			anim_player.play(next_animation)
			await anim_player.animation_finished
			if not cutscene_over:
				set_cutscene_over()
	else:
		set_cutscene_over()


# Editor-friendly wrapper: uses exported defaults so you don't have to type args
func play_default_dialog_then_animation() -> void:
	await queue_dialog_then_animation(default_dialogue_path, String(default_next_animation))
