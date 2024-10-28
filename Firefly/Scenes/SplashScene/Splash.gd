extends UiComponent
@onready var animation_player = $AnimationPlayer


# Called when the node enters the scene tree for the first time.
func _ready():
	
	animation_player.play("RESET")
	await get_tree().create_timer(1.0).timeout
	animation_player.play("splash")


func _input(event):
	if not _loader.loading:
		if event.is_action("ui_accept"):
			_loader.load_level("res://Scenes/Levels/TitleScreen/title_screen.tscn")
	


func _on_animation_player_animation_finished(anim_name):
	
	if anim_name == "splash":
		await get_tree().create_timer(1.0).timeout
		animation_player.play("wipe")
	elif anim_name == "wipe":
		_loader.load_level("res://Scenes/Levels/TitleScreen/title_screen.tscn")
	
