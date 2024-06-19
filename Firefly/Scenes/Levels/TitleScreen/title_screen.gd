extends "res://Scripts/Level/Level.gd"



@onready var music = $LevelAudio/Music
@onready var ambience = $LevelAudio/Ambience
@onready var moonlight = $"PP + FX/Moonlight"
@onready var shadow_filter = $"PP + FX/ShadowFilter"


# We have the player start without glow on this level
func player_startup_logic():
	
	PLAYER.lock_h_dir(0.2, 1.5)


# And becasue of that we hide the gems
func gem_startup_logic():
	
	gem_manager.hide_gems()

func local_ready():

	music.play(0)
	ambience.play(0)
	
	moonlight.visible = true
	shadow_filter.visible = true
	
	_audio.set_level_effects([])
