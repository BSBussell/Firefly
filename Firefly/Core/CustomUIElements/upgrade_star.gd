extends UiComponent
class_name StarParticles

@onready var burst_particles: CPUParticles2D = $SubViewportContainer/SubViewport/StarPosition/burst_particles

@onready var sub_viewport = $SubViewportContainer/SubViewport
@onready var sub_viewport_container = $SubViewportContainer

@onready var l = $L

# Called when the node enters the scene tree for the first time.
func _ready():
	
	if context:
		context.PLAYER.connect_upgrade(Callable(self, "burst"))
	
	var config_changed = Callable(self, "config_changed")
	_config.connect_to_config_changed(config_changed)
	config_changed.call()



var stored_delta: float = 0.016
func _process(delta):
	stored_delta = delta

var block: bool = false
func burst(amount: int = 64) -> void:
	
	# Ensure only called every 1 secs
	if block: return
	block = true
	
	burst_particles.amount = amount 
	burst_particles.emitting = true
	
	# Unlcok after 3 seconds
	await burst_particles.finished
	block = false  

var burn_block: bool  = false

func toggle_burn(level: int = 0, points: int = 0) -> void:
	var speed: float = lerpf(0.1, 0.2, points / 100)
	var particles: Array[Node] = []
	var off: Array[Node] = []

	# Predefine particle groups and speed ranges per level
	var levels = ["L0_Particles", "L1_Particles", "L2_Particles"]
	var speed_ranges = [[0.1, 0.15], [0.1, 0.2], [0.15, 0.3]]

	# Process levels and assign particles to active or off groups
	for i in range(levels.size()):
		var group_nodes = get_tree().get_nodes_in_group(levels[i])
		if level >= i:
			particles.append_array(group_nodes)
			speed = lerpf(speed_ranges[i][0], speed_ranges[i][1], points / 100)
		else:
			off.append_array(group_nodes)

	# Activate particles
	for each in particles:
		var particle_node: CPUParticles2D = each as CPUParticles2D
		if particle_node:
			particle_node.emitting = true
			var target_speed: float = speed * (1.5 if particle_node.is_in_group("L2_Particles") else 1.0)
			particle_node.speed_scale = move_toward(particle_node.speed_scale, target_speed, 0.001) if particle_node.speed_scale < target_speed else target_speed

	# Deactivate particles
	for each in off:
		var particle_node: CPUParticles2D = each as CPUParticles2D
		if particle_node:
			particle_node.emitting = false
 

func config_changed() -> void:
	
	# Scale viewport container to display
	var size: Vector2 = sub_viewport.size
	var res: Vector2 = DisplayServer.window_get_size()
	sub_viewport_container.scale = ceil(res / size)
	
