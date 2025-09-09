extends AnimatedSprite2D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_challenge_gg_body_entered(body):
	if body.global_position.x > global_position.x:
		flip_h = true
	else:
		flip_h = false
