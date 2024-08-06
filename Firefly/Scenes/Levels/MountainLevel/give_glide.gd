extends DialogueArea2D




func _on_finish_dialogue():
	
	# The player can glide now
	level.PLAYER.can_glide = true
