extends Node

var shake_timer: Timer
var shake_direction: Vector2
var shake_intensity: float
var shake_duration: float

func _ready():
	shake_timer = Timer.new()
	shake_timer.connect("timeout", Callable(self, "_on_shake_timer_timeout"))
	add_child(shake_timer)
	set_process(true)

# DO NOT USE THIS IT IS FUCKED
func shake_screen(direction: Vector2, intensity: float, duration: float):
	shake_direction = direction.normalized()
	shake_intensity = intensity
	shake_duration = duration
	shake_timer.start(duration)

func _process(_delta):
	if shake_timer.is_stopped() == false:
		var time_ratio = shake_timer.time_left / shake_duration
		var shake_magnitude = shake_intensity * time_ratio
		var offset = shake_direction * sin(Time.get_ticks_msec() * 0.1) * shake_magnitude
		_viewports.game_viewport_container.material.set_shader_parameter("sub_pixel_offset", offset)

func _on_shake_timer_timeout():
	_viewports.game_viewport_container.material.set_shader_parameter("sub_pixel_offset", Vector2.ZERO)
