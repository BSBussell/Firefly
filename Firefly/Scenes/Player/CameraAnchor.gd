extends Marker2D

@export var Player: Flyph
@export var speed = 0.2

enum process {Physics, Draw}

@export var processor: process


# Called when the node enters the scene tree for the first time.
func _ready():
	
	pass # Replace with function body.


func _physics_process(delta):
	
	if processor == process.Physics:
		var target = Player.global_position
		
		var follow_target = Vector2.ZERO
		follow_target.x = int(lerp(global_position.x, target.x, speed))
		follow_target.y = int(lerp(global_position.y, target.y, speed))
		
		global_position = follow_target
	
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	if processor != process.Physics:
		var target = Player.global_position
		
		var follow_target = Vector2.ZERO
		follow_target.x = int(lerp(global_position.x, target.x, speed))
		follow_target.y = int(lerp(global_position.y, target.y, speed))
		
		global_position = follow_target
	
	pass
