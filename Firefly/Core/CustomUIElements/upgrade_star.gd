extends UiComponent
class_name StarParticles

@onready var burst_particles: CPUParticles2D = $SubViewportContainer/SubViewport/StarPosition/burst_particles

@onready var l_continuous_particles = $SubViewportContainer/SubViewport/StarPosition/L_continuous_particles
@onready var r_continuous_particles = $SubViewportContainer/SubViewport/StarPosition/R_continuous_particles


@onready var sub_viewport = $SubViewportContainer/SubViewport
@onready var sub_viewport_container = $SubViewportContainer


# Called when the node enters the scene tree for the first time.
func _ready():
	
	if context:
		context.PLAYER.connect_upgrade(Callable(self, "burst"))
	
	var config_changed = Callable(self, "config_changed")
	_config.connect_to_config_changed(config_changed)
	config_changed.call()



var block: bool = false
func burst(amount: int = 64) -> void:
	
	# Ensure only called every 1 secs
	if block: return
	block = true
	
	burst_particles.amount = amount/2
	burst_particles.emitting = true
	
	# Unlcok after 3 seconds
	await burst_particles.finished
	block = false  

var burn_block: bool  = false
func toggle_burn(state: bool = true, scale: float = 0.5) -> void:
	
	if state == true:
		burn_block = false
	if burn_block: return
	
	
	if l_continuous_particles.emitting and not state:
		burn_block = true
		l_continuous_particles.one_shot = true
		r_continuous_particles.one_shot = true
		await l_continuous_particles.finished
		l_continuous_particles.one_shot = false
		r_continuous_particles.one_shot = false  
		burn_block = false
		
	l_continuous_particles.emitting = state
	l_continuous_particles.speed_scale = scale
	
	r_continuous_particles.emitting = state
	r_continuous_particles.speed_scale = scale
	
	
	
	

func config_changed() -> void:
	
	# Scale viewport container to display
	var size: Vector2 = sub_viewport.size
	var res: Vector2 = DisplayServer.window_get_size()
	sub_viewport_container.scale = ceil(res / size)
	
