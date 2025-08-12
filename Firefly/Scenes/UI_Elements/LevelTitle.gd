extends UiComponent

@onready var animation_player = $AnimationPlayer
@onready var label = $Label


var title_text: String = "oop"
var animation_finished: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	
	# Set title text
	title_text = context.Text
	label.text = title_text
	
	
	
	if _globals.ACTIVE_PLAYER and not _globals.ACTIVE_PLAYER.is_on_floor():
		# Wait until the player is on the floor
		await get_tree().process_frame  # make sure physics has run at least once
		while not _globals.ACTIVE_PLAYER.is_on_floor():
			await get_tree().physics_frame
		
		# Optional delay before playing
		await get_tree().create_timer(1.0).timeout
		
	animation_player.play("Drop-In")


# Leave the LevelTitle Text on until input
func _unhandled_input(_event):
	
	# If the animation finished, fade out
	if animation_finished:
		animation_player.play("Fade-Out")
	
func _on_animation_player_animation_finished(_anim_name):
	
	
	# Modify the animation to work with the current font size(cause dynamic resizing)
	var font_size: int = label.get_theme_font_size("font_size")
	animation_player.get_animation("Fade-Out").track_set_key_value(1, 0, font_size)
	animation_player.get_animation("Fade-Out").track_set_key_value(1, 1, font_size * 1.6)
	
	# Let the animation end if it wants too
	animation_finished = true
	


