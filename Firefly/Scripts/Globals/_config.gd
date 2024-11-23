extends Node

# Signal Config Changed
signal config_changed

# Configuration file path
const CONFIG_FILE: String = "user://config.json"

# Game settings
var def_settings: Dictionary = {
	

	
# Gameplay
	
	"auto_glow": false,
	"show_speedometer": 0,
	"show_timer": false,
	
	
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
	"inf_jump": false
}

var settings: Dictionary = def_settings

# Called when the node is added to the scene
func _ready() -> void:
	load_settings()

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
		var config_data: String = JSON.stringify(settings)
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

