extends Node
class_name DiscordManager


# Have no idea what data type this is
var app_id: int = 1351304226122498181 # Application ID
var launch_time: int = 0

func _ready() -> void:
	
	# Setup the default information
	DiscordRPC.app_id = app_id
	DiscordRPC.details = "a 🐝 game" #found on bbussell.com/firefly"
	DiscordRPC.state = "Explorin" # Default state, we're exploring
	
	# Set the image as a the jar that is the game's icon
	DiscordRPC.large_image = "flyjar"
	DiscordRPC.large_image_text = "The Jar"

	
	# Sneakily set a party id, that way I can modify the party size to display the players collected jars
	DiscordRPC.party_id = "firefly-fake-activity"
	

	# By default sync the time just to game start time
	launch_time = int(Time.get_unix_time_from_system())
	DiscordRPC.start_timestamp = launch_time
	

	DiscordRPC.refresh() # Always refresh after changing the values!
	
	
# Sync the displayed timestamp to the game time
func sync_to_game_time(time: float) -> void:
	
	if (DiscordRPC.get_is_discord_working()):
		# Set the time to the current time
		DiscordRPC.start_timestamp = int(Time.get_unix_time_from_system()) - int(time)
		DiscordRPC.refresh()
	
func sync_to_launch_time() -> void:
	
	if (DiscordRPC.get_is_discord_working()):
		# Set the time to the current time
		DiscordRPC.start_timestamp = launch_time
		DiscordRPC.refresh()

# Function for updating the state
func update_state(new_state: String) -> void:
	
	if (DiscordRPC.get_is_discord_working()):
		DiscordRPC.state = new_state
		DiscordRPC.refresh()

func hide_jar_count() -> void:
	
	if (DiscordRPC.get_is_discord_working()):
		# Reset the party size to 0 so we don't display anything
		DiscordRPC.current_party_size = 0
		DiscordRPC.max_party_size = 0
		
		DiscordRPC.refresh()

func update_jar_count() -> void:
	
	if (DiscordRPC.get_is_discord_working()):
		# Set the party size to the number of jars nabbed
		DiscordRPC.current_party_size = _jar_tracker.total_num_found_jars()
		DiscordRPC.max_party_size = _jar_tracker.total_num_known_jars()
		
		DiscordRPC.refresh()
