extends Area2D

@export var Gems: GemManager = null

@export var animation_player: AnimationPlayer
@export var swoosh: AudioStreamPlayer2D

# Called when the node enters the scene tree for the first time.
func _ready():
	
	await _loader.finished_loading
	
	if Gems == null:
		Gems = $"../../GemManager"
		
	if _globals.ACTIVE_PLAYER.can_glow():
		queue_free()



func _on_body_entered(body):
	
	var player: Flyph = body as Flyph
	if player and not player.can_glow():
		
		player.enable_glow()
		player.set_glow_score(100)
		await get_tree().create_timer(0.1).timeout
		
		# hehe
		player.horizontal_axis = -1
		var new_velocity = Vector2(0,0) # player.velocity
		new_velocity.x = -400
		new_velocity.y = player.jump_velocity
		
		player.lock_h_dir(-1,0.3, true)
		player.launch(new_velocity)
		
		#player.give_boost(player.movement_data.GLOW_UPGRADE_BOOST)
		
		# Show gimms now
		Gems.show_gems()
		
		# Spawn the rings behind the player
		player.spawn_rings()
		
		swoosh.play()
		animation_player.play("Use")
		
		#queue_free()
		
