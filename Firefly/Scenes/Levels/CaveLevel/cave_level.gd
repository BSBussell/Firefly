extends "res://Scripts/Level/Level.gd"



@onready var music = $LevelAudio/Music
@onready var ambience = $LevelAudio/Ambience
@onready var lighting = $Lighting

@onready var ropes = $SwingAbleRopes



# And becasue of that we hide the gems
func gem_startup_logic():
	
	gem_manager.hide_gems()

func local_ready():

	print("Setting up Cave Level")

	# Start playing the music
	music.play(0)
	ambience.play(0)

	_discord.update_state("Explorin' a Cave")
	_discord.update_jar_count()
	
	# Enable Reverb Audio Filer
	_audio.set_level_effects([0])  


	
	# Enable Specific Visuals that are left off in the editor for visibility
	lighting.visible = true
	
func player_startup_logic():
	
	PLAYER.lock_h_dir(0,1)
	return


func on_death():
	
	ropes.reset_worms()
	gem_manager.respawn_all()
