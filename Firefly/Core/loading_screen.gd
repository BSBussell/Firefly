extends ColorRect

@onready var animation_player = $AnimationPlayer
@onready var progress_bar = $ProgressBar

func _ready():

	animation_player.play("RESET")
	scale_shader()	

	progress_bar.value = 0


func _process(_delta):

	# Create array with one element
	var progress = [0]

	# Get the progress of the game
	if (ResourceLoader.load_threaded_get_status(_loader.current_path, progress) == 1):
		print("Loading: ", progress[0])


	# Set the progress bar value
	progress_bar.set_target_value(progress[0] * 100.0)
	
	scale_shader()


func play_animation(animation: String):
	animation_player.play(animation)


func _on_animation_player_animation_finished(anim_name:StringName):
	
	if anim_name == "load_in":
		play_animation("bounce")
		
func scale_shader():
	# Calculate screen size
	var render_size = DisplayServer.window_get_size()

	# Divide Screen size by 15
	var triangle_size: int = render_size.x 


	# Get the shader material attached to the ColorRect
	material.set("shader_parameter/diamondPixelSize", triangle_size)
	
