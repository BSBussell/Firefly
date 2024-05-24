extends UiComponent
class_name StarParticles

@onready var particles: CPUParticles2D = $Star

# Called when the node enters the scene tree for the first time.
func _ready():
	context.PLAYER.connect_upgrade(Callable(self, "upgrade"))



func upgrade():
	var window_size = DisplayServer.window_get_size()
	particles.emission_rect_extents.x = window_size.x/2
	particles.emitting = true
