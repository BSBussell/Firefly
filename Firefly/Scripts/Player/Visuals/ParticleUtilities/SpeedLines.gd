extends CPUParticles2D


var player: Flyph

# Called when the node enters the scene tree for the first time.
func _ready():
	player = _globals.ACTIVE_PLAYER
	var velocity = player.velocity
	set_properties()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	set_properties()


func set_properties():
	var velocity = -player.velocity
	
	direction = velocity.normalized()
	
	
	if direction.x > 0:
		position.x = -7
	else:
		position.x = 7
	
	
