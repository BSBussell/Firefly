extends Area2D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_body_entered(body):
	
	var flyph: Flyph = body as Flyph
	if flyph:
		flyph.AERIAL_STATE.fall_timer = 0
		flyph.spotlight.set_brightness(0)


func _on_body_exited(body):
	var flyph: Flyph = body as Flyph
	if flyph:
		flyph.AERIAL_STATE.fall_timer = 0
		flyph.spotlight.set_brightness(flyph.movement_data.BRIGHTNESS)
