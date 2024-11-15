extends Label


@export var plat: MovingPlat

# Called when the node enters the scene tree for the first time.
func _ready():
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if plat:
		text = str(floor(plat.actual_velocity.length()))    
