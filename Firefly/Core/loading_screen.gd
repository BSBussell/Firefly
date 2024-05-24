extends ColorRect

@onready var animation_player = $AnimationPlayer


func _ready():

	# Calculate screen size
	var render_size = DisplayServer.window_get_size()

	# Divide Screen size by 15
	var triangle_size: int = render_size.x / 5


	# Get the shader material attached to the ColorRect
	print(triangle_size)
	material.set("shader_parameter/diamondPixelSize", triangle_size)


func play_animation(animation: String):
	animation_player.play(animation)
