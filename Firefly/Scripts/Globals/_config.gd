extends Node

# Configuration file path
const CONFIG_FILE: String = "user://config.json"

# Game settings
var settings: Dictionary = {
    "game_zoom": 1.0,

	"mixer_settings": {
        "sfx": 1.0,
        "music": 1.0,
        "ambience": 1.0
    },

    "fullscreen": false,
    "auto_glow": false,
	"show_speedometer": false,
    "show_timer": false
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

# Get a setting value by key
func get_setting(key: String) -> Variant:
    return settings.get(key)

# Set a setting value by key and save to file
func set_setting(key: String, value: Variant) -> void:
    settings[key] = value
    save_settings()
