extends UiComponent

@onready var animation_player = $AnimationPlayer
@onready var label = $Label


var title_text: String = "oop"

#func set_title(title: String):
	
	#title_text = title

# Called when the node enters the scene tree for the first time.
func _ready():
	
	title_text = context.Text
	label.text = title_text
	update_font_size()
	await get_tree().create_timer(1.0).timeout
	animation_player.play("Drop-In")


var animation_finished: bool = false
func _unhandled_input(event):
	if animation_finished and event.is_action_pressed("Jump"):
		#await get_tree().create_timer(2.0).timeout
		animation_player.play("Fade-Out")
	

func _on_animation_player_animation_finished(anim_name):
	animation_finished = true


func update_font_size():
	var base_resolution = Vector2(1920, 1080)  # Base development resolution
	var current_resolution = DisplayServer.window_get_size()
	
	# Calculate the scaling factor based on height or width (whichever you prefer)
	# This example uses the width to calculate the scaling factor
	var scale_factor = current_resolution.x / base_resolution.x
	
	# Set the font size based on the scaling factor
	var new_font_size = int(64 * scale_factor)  # 64 is the base font size at 1920x1080

	label.label_settings.font_size = new_font_size
