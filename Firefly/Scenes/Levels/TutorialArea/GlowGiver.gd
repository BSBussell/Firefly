extends Area2D

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_body_entered(body):
	
	var player: Flyph = body as Flyph
	if player and not player.can_glow():
		player.enable_glow()
		player.set_glow_score(100)
		await get_tree().create_timer(0.1).timeout
		
		# hehe
		player.horizontal_axis = -1
		var new_velocity = player.velocity
		new_velocity.x = -player.movement_data.GLOW_UPGRADE_BOOST * 4
		new_velocity.y = player.jump_velocity
		player.launch(new_velocity)
		#player.give_boost(player.movement_data.GLOW_UPGRADE_BOOST)
		
		queue_free()
