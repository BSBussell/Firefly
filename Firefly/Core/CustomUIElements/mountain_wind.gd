extends "res://Scripts/UI/UIComponent.gd"
class_name MTN_Wind
@onready var sub_viewport_container = $SubViewportContainer
@onready var sub_viewport = $SubViewportContainer/SubViewport

@onready var lines = $SubViewportContainer/SubViewport/CenterLeft/Lines
@onready var dust = $SubViewportContainer/SubViewport/CenterLeft/Dust


# Called when the node enters the scene tree for the first time.
func _ready():
	var config_changed = Callable(self, "config_changed")
	_config.connect_to_config_changed(config_changed)
	config_changed.call()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	#_viewports.viewer.res_scale
	pass


func config_changed() -> void:
	
	# Scale viewport container to display
	var size: Vector2 = sub_viewport.size
	var res: Vector2 = DisplayServer.window_get_size()
	sub_viewport_container.scale = ceil(res / size)
	
