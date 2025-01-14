extends UiComponent
class_name StarParticles

@onready var burst_particles: CPUParticles2D = $SubViewportContainer/SubViewport/StarPosition/burst_particles

@onready var sub_viewport = $SubViewportContainer/SubViewport
@onready var sub_viewport_container = $SubViewportContainer


# Called when the node enters the scene tree for the first time.
func _ready():
	context.PLAYER.connect_upgrade(Callable(self, "upgrade"))
	
	var config_changed = Callable(self, "config_changed")
	_config.connect_to_config_changed(config_changed)
	config_changed.call()



var block: bool = false
func upgrade():
	
	# Ensure only called every 1 secs
	if block: return
	block = true
	
	burst_particles.emitting = true
	
	# Unlcok after 3 seconds
	await get_tree().create_timer(1.0).timeout
	block = false


func config_changed():
	
	# Scale viewport container to display
	var size: Vector2 = sub_viewport.size
	var res: Vector2 = DisplayServer.window_get_size()
	sub_viewport_container.scale = ceil(res / size)
	
