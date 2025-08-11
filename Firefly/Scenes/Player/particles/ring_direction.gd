extends CPUParticles2D


var player: Flyph

# Called when the node enters the scene tree for the first time.
func _ready():
	player = _globals.ACTIVE_PLAYER
	var velocity = player.velocity
	
	var angle_deg = 20 if velocity.x > 0 else -20
	
	
	
	angle_deg = 0
	
	# If we're in place enough
	if abs(player.horizontal_axis) <= 0.2:
		angle_deg = -90
		
	angle_min = angle_deg
	angle_max = angle_deg
	set_properties()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	set_properties()


func set_properties():
	var velocity = -player.velocity
	
	
	
	direction = velocity.normalized()
	
