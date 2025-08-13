extends Node

# Signal Config Changed
signal config_changed

# Configuration file path
const CONFIG_FILE: String = "user://config.json"

# Game settings
var def_settings: Dictionary = {
	

	
# Gameplay
	"auto_glow": true,
	"show_speedometer": 0,
	"show_timer": false,
	"discord_timer": false,
	"skip_jar_reveal": false,
	
# Graphics
	"fullscreen": true,
	"resolution": 0,
	"fps_target": 1,
	"vsync": true,
	"game_zoom": 1.4,
	
# Audio
	"master_vol": 0.0,
	"sfx": 1.0,
	"music": 0.0,
	"ambience": -1.0,

# Helpers
	"input_assist": true,
	"slide_assist": true,
	"inf_jump": false,
	"walljump_hold_into_up": true,

# Input bindings (stored as serialized data)
	"input_bindings": {}
}

var settings: Dictionary = def_settings

# Called when the node is added to the scene
func _ready() -> void:
	load_settings()
	load_input_bindings()

# Load input bindings from config and apply to InputMap
func load_input_bindings() -> void:
	var input_bindings = settings.get("input_bindings", {})
	
	for action_name in input_bindings.keys():
		if not InputMap.has_action(action_name):
			continue
			
		# Clear existing events for this action
		InputMap.action_erase_events(action_name)
		
		# Add each stored event
		var events_data = input_bindings[action_name]
		for event_data in events_data:
			var event = deserialize_input_event(event_data)
			if event:
				InputMap.action_add_event(action_name, event)

# Save current InputMap bindings to config
func save_input_bindings() -> void:
	var input_bindings = {}
	
	# Get all actions and their events
	for action_name in InputMap.get_actions():
		# Skip UI actions - we don't want to let users rebind those
		if action_name.begins_with("ui_"):
			continue
			
		var events = InputMap.action_get_events(action_name)
		var serialized_events = []
		
		for event in events:
			if event is InputEventKey or event is InputEventJoypadButton or event is InputEventJoypadMotion:
				serialized_events.append(serialize_input_event(event))
		
		if serialized_events.size() > 0:
			input_bindings[action_name] = serialized_events
	
	settings["input_bindings"] = input_bindings
	save_settings()

# Serialize an InputEvent to a dictionary
func serialize_input_event(event: InputEvent) -> Dictionary:
	var data = {
		"type": event.get_class()
	}
	
	if event is InputEventKey:
		var key_event = event as InputEventKey
		data["keycode"] = key_event.keycode
		data["physical_keycode"] = key_event.physical_keycode
		data["key_label"] = key_event.key_label
		data["unicode"] = key_event.unicode
		data["ctrl_pressed"] = key_event.ctrl_pressed
		data["shift_pressed"] = key_event.shift_pressed
		data["alt_pressed"] = key_event.alt_pressed
		data["meta_pressed"] = key_event.meta_pressed
		
	elif event is InputEventJoypadButton:
		var joy_event = event as InputEventJoypadButton
		data["button_index"] = joy_event.button_index
		data["device"] = joy_event.device
		
	elif event is InputEventJoypadMotion:
		var motion_event = event as InputEventJoypadMotion
		data["axis"] = motion_event.axis
		data["axis_value"] = motion_event.axis_value
		data["device"] = motion_event.device
	
	return data

# Deserialize a dictionary back to an InputEvent
func deserialize_input_event(data: Dictionary) -> InputEvent:
	var event_type = data.get("type", "")
	
	if event_type == "InputEventKey":
		var event = InputEventKey.new()
		event.keycode = data.get("keycode", 0)
		event.physical_keycode = data.get("physical_keycode", 0)
		event.key_label = data.get("key_label", 0)
		event.unicode = data.get("unicode", 0)
		event.ctrl_pressed = data.get("ctrl_pressed", false)
		event.shift_pressed = data.get("shift_pressed", false)
		event.alt_pressed = data.get("alt_pressed", false)
		event.meta_pressed = data.get("meta_pressed", false)
		event.pressed = true
		return event
		
	elif event_type == "InputEventJoypadButton":
		var event = InputEventJoypadButton.new()
		event.button_index = data.get("button_index", 0)
		event.device = data.get("device", -1)
		event.pressed = true
		return event
		
	elif event_type == "InputEventJoypadMotion":
		var event = InputEventJoypadMotion.new()
		event.axis = data.get("axis", 0)
		event.axis_value = data.get("axis_value", 0.0)
		event.device = data.get("device", -1)
		return event
	
	return null

# Reset input bindings to defaults
func reset_input_bindings_to_default() -> void:
	settings["input_bindings"] = {}
	save_settings()
	
	# Reload the project's default InputMap
	# This is a bit tricky since we need to restore the original bindings
	# For now, we'll just clear the config and let the game restart with defaults
	_logger.info("Input bindings reset to default. Please restart the game.")

# Connect a callable to input bindings changed
func connect_to_input_changed(_function: Callable) -> void:
	# We could emit a signal when input bindings change
	pass

# Load settings from the configuration file
func load_settings() -> void:
	var file: FileAccess = FileAccess.open(CONFIG_FILE, FileAccess.READ)
	if file:
		var config_data: String = file.get_as_text()
		var json: JSON = JSON.new()
		var error: Error = json.parse(config_data)
		if error == OK:
			settings = json.data
		file.close()
		ensure_def_keys_exist()
	else:
		save_settings()  # Save default settings if config file doesn't exist

func ensure_def_keys_exist() -> void:
	# Ensure all keys in default settings exist and match the expected type
	for key in def_settings.keys():
		if settings.has(key):
			# Check if the type matches, and if not, convert or reset
			var default_type = typeof(def_settings[key])
			if typeof(settings[key]) != default_type:
				settings[key] = cast_value(settings[key], def_settings[key])
		else:
			# Add missing default keys
			settings[key] = def_settings[key]

	# Save the corrected settings back
	save_settings()

# Helper to cast or reset values to the default type
func cast_value(old_value: Variant, default_value: Variant) -> Variant:
	match typeof(default_value):
		TYPE_BOOL:
			return bool(old_value)
		TYPE_INT:
			return int(old_value)
		TYPE_FLOAT:
			return float(old_value)
		TYPE_STRING:
			return str(old_value)
		TYPE_ARRAY:
			return old_value if typeof(old_value) == TYPE_ARRAY else []
		TYPE_DICTIONARY:
			return old_value if typeof(old_value) == TYPE_DICTIONARY else {}
		_:
			return default_value  # Use default for unknown types


# Save current settings to the configuration file
func save_settings() -> void:
	var file: FileAccess = FileAccess.open(CONFIG_FILE, FileAccess.WRITE)
	if file:
		var config_data: String = JSON.stringify(settings, "\t")
		file.store_string(config_data)
		file.close()

	emit_signal("config_changed")

# Get a setting value by key
func get_setting(key: String) -> Variant:
	if settings.has(key):
		return settings.get(key)
	else:
		return null

# Set a setting value by key and save to file
func set_setting(key: String, value: Variant) -> void:
	
	# Make sure we are actually changing things
	if value != settings[key]:
		settings[key] = value
		save_settings()

## Connect a callable to the config changed signal. KEEP IT LIGHT!!
func connect_to_config_changed(function: Callable) -> void:
	connect("config_changed", function)

