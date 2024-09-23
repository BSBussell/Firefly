extends DialogueArea2D


@export var super_secret_based_dialogue: DialogueData


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("interact"):
		
		if dialogue_ui.dialogue_up: return

		# If you beat the game without obtaining glide, and without using assists!
		if not level.PLAYER.can_glide and not _stats.INVALID_RUN: dialogue = super_secret_based_dialogue
		
		# Start Displaying Dialogue
		_start_dialogue()
