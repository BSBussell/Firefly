extends Area2D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func _on_body_entered(body: Flyph):
	
	#body.set_temp_gravity(parent.spring)
	
	body.spring_body_entered(body)
	pass # Play animation here?



func _on_body_exited(body: Flyph):
	body.spring_body_exited(body)
	pass # Replace with function body.
