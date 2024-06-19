extends "res://Scripts/Level/Level.gd"



@onready var music = $LevelAudio/Music
@onready var ambience = $LevelAudio/Ambience
@onready var moonlight = $"PP + FX/Moonlight"
@onready var shadow_filter = $"PP + FX/ShadowFilter"

@onready var timer = $Timer



# And becasue of that we hide the gems
func gem_startup_logic():
	
	gem_manager.hide_gems()

func local_ready():

	music.play(0)
	ambience.play(0)
	
	moonlight.visible = true
	shadow_filter.visible = true
	
	timer.start(0.2)
	
	_audio.set_level_effects([])




func _on_timer_timeout():
	
	var dir: float = snappedf( randf_range(-0.3, 0.3), 0.1)
	
	print(dir)
	
	# Float weirdness
	const TOLERANCE: float = 0.0001

	if abs(abs(dir) - 0.3) > TOLERANCE:
		dir = 0.0
		
	print(dir)
	
	var dur: float = snappedf( randf_range(1.0, 3.5), 0.1)
	
	PLAYER.lock_h_dir(dir, dur, true)
	timer.wait_time = dur
