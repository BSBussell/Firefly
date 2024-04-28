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

	print("Setting up Tutorial Level")

	# Start playing the music
	music.play(0)
	ambience.play(0)
	
	_audio.set_level_effects([])

	
	# Enable Specific Visuals that are left off in the editor for visibility
	lighting.visible = true


