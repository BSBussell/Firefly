extends "res://Scripts/Level/Level.gd"

@export var nextLevel: PackedScene



@onready var music = $LevelAudio/Music
@onready var ambience = $LevelAudio/Ambience
@onready var moonlight = $"PP + FX/Moonlight"
@onready var shadow_filter = $"PP + FX/ShadowFilter"

@onready var animation_player = $AnimationPlayer




# And becasue of that we hide the gems
func gem_startup_logic():
	
	gem_manager.hide_gems()

func local_ready():

	music.play(0)
	ambience.play(0)
	
	moonlight.visible = true
	shadow_filter.visible = true

	_discord.update_state("Explorin' the main menu")
	_discord.hide_jar_count()
	
	
	await get_tree().create_timer(10.0).timeout
	animation_player.play("MoveCamera")
	
	_audio.set_level_effects([])



func next_level() -> void:
	
	load_level(nextLevel.resource_path, '')
