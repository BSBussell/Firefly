extends Node

# Signal Config Changed
signal config_changed

# Configuration file path
const CONFIG_FILE: String = "user://config.json"

# Game settings
var settings: Dictionary = {
	

	
# Gameplay
	
	"auto_glow": false,
	"input_assists": false,
	"show_speedometer": false,
	"show_timer": false,
	
	
# Graphics
	"fullscreen": false,
	"vsync": false,
	"game_zoom": 1.0,
	
# Audio
	"master_vol": 0.0,
	"sfx": 1.0,
	"music": 0.0,
	"ambience": -1.0

}

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
	else:
		save_settings()  # Save default settings if config file doesn't exist

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
	settings[key] = value
	save_settings()


func connect_to_config_changed(function: Callable) -> void:
	connect("config_changed", function)
