extends ParallaxBackground

@onready var fire_fly_particles = $FireFlies2/FireFlyParticles
@onready var fire_fly_particles2 = $FireFlies/FireFlyParticles

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	'''
	if _input_manager.was_pressed(&"Dive"):
		visible = not visible
		fire_fly_particles.emitting = visible
		fire_fly_particles2.emitting = visible
	'''
	pass
		
