extends "res://Scripts/Level/Level.gd"



@onready var music = $LevelAudio/Music
@onready var ambience = $LevelAudio/Ambience

@onready var lighting = $Lighting



# We have the player start without glow on this level
func player_startup_logic():
	
	PLAYER.disable_glow()


# And becasue of that we hide the gems
func gem_startup_logic():
	
	gem_manager.hide_gems()

func local_ready():

	print("Setting up Cave Level")

	# Start playing the music
	music.play(0)
	ambience.play(0)
	
	# Enable Reverb Audio Filer
	#var bus_idx = AudioServer.get_bus_index("Master")
	#AudioServer.set_bus_effect_enabled(bus_idx, 0, true)


	
	# Enable Specific Visuals that are left off in the editor for visibility
	lighting.visible = true


