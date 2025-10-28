extends UiComponent

@onready var animation_player = $TextAnimation


# Called when the node enters the scene tree for the first time.
func _ready():
	
	get_tree().paused = true
	
	# await finish loading to unify
	await _loader.finished_loading
	await get_tree().create_timer(1.0).timeout
	animation_player.play("RaiseCurtain")
	
	#await get_tree().create_timer(2.0).timeout
	
	
	
	
	pass

func unpause() -> void:
	get_tree().paused = false	




var fade_in: bool = false
func _on_text_animation_animation_finished(anim_name):
	if anim_name == "RaiseCurtain":
		animation_player.play("FadeIn")
		fade_in = true
	elif anim_name == "FadeIn":
		await get_tree().create_timer(6.0).timeout
		animation_player.play("Close")
	
