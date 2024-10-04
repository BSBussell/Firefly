extends "res://Scripts/Level/Level.gd"



@onready var music = $LevelAudio/Music
@onready var ambience = $LevelAudio/Ambience
@onready var cave_entrance = $LevelAudio/CaveEntrance

@onready var lighting = $Lighting



# We have the player start without glow on this level
func player_startup_logic():
	
	# Play the walk in script
	if spawn_point_id:
		PLAYER.lock_h_dir(0.2, 1.5)


# And becasue of that we hide the gems
func gem_startup_logic():
	
	#if not spawn_point_id:
		#gem_manager.hide_gems()
	#else:
	gem_manager.show_gems()

func local_ready():

	print("Setting up Tutorial Level")

	# Start playing the music
	music.play(0)
	ambience.play(0)
	#cave_entrance.play(0)
	
	_audio.set_level_effects([])

	
	# Enable Specific Visuals that are left off in the editor for visibility
	lighting.visible = true


func on_death():
	
	gem_manager.respawn_all()
