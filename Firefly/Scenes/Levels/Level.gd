extends Node2D
class_name Level

@export var PLAYER: Flyph

@onready var music = $LevelAudio/Music
@onready var ambience = $LevelAudio/Ambience
@onready var moonlight = $"PP + FX/Moonlight"
@onready var shadow_filter = $"PP + FX/ShadowFilter"
@onready var gem_manager = $GemManager



func _ready():

	# Register Global Components
	_globals.ACTIVE_PLAYER = PLAYER
	_globals.GEM_MANAGER = gem_manager

	# Enable Specific Visuals that are left off in the editor for visibility
	gem_manager.hide_gems()
	music.play(0)
	ambience.play(0)
	PLAYER.disable_glow()
	moonlight.visible = true
	shadow_filter.visible = true
	pass
