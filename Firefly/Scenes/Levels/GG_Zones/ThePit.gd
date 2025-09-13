extends "res://Scripts/Level/Level.gd"



@onready var music = $LevelAudio/Music
@onready var ambience = $LevelAudio/Ambience
@onready var lighting = $Lighting
@onready var marimba = $LevelAudio/Marimba



# We have the player start without glow on this level
func player_startup_logic():
	
	PLAYER.spotlight.set_brightness(0)
	
		


# And becasue of that we hide the gems
func gem_startup_logic():
	
	gem_manager.show_gems()

func local_ready():

	print("Setting up Blah Level")

	# Start playing the music
	music.play(0)
	#marimba.play(0)
	ambience.play(0)
	#cave_entrance.play(0)

	_discord.update_state("Navigatin' a gorge")
	_discord.update_jar_count()

	_audio.set_level_effects([])

	
	# Enable Specific Visuals that are left off in the editor for visibility
	lighting.visible = true


func on_death():
	
	gem_manager.respawn_all()
