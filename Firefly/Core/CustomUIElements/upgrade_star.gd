extends UiComponent
class_name StarParticles

@onready var particles: CPUParticles2D = $Star

# Called when the node enters the scene tree for the first time.
func _ready():
	context.PLAYER.connect_upgrade(Callable(self, "upgrade"))



var block: bool = false
func upgrade():
	
	# Ensure only called every 3 secs
	if block: return
	block = true
	
	# Resize for windo and emit
	var window_size = DisplayServer.window_get_size()
	particles.emission_rect_extents.x = window_size.x/2
	particles.lifetime = float(window_size.y)/(980.0*1.2)
	particles.emitting = true
	
	# Unlcok after 3 seconds
	await get_tree().create_timer(3.0).timeout
	block = false
