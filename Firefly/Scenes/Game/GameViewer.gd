extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	
	# Set our global viewports
	_viewports.game_viewport_container = $GameContainer
	_viewports.game_viewport = $GameContainer/GameViewPort


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
