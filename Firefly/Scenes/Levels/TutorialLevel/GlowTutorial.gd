extends DialogueArea2D




func _on_finish_dialogue():
	level.PLAYER.enable_glow()
	level.gem_manager.show_gems()
