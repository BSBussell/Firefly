extends UiComponent
@onready var animation_player = $AnimationPlayer


# Called when the node enters the scene tree for the first time.
func _ready():
	animation_player.play("splash")




func _on_animation_player_animation_finished(anim_name):
	
	if anim_name != "wipe":
		await get_tree().create_timer(1.0).timeout
		animation_player.play("wipe")
	else:
		_loader.load_level("res://Scenes/Levels/TitleScreen/title_screen.tscn")
	
