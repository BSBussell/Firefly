extends ParallaxLayer

@export var fade_height: float = -200.0      # If player.y < this, fade out
@export var fade_duration: float = 0.35      # Seconds for each fade
@export var player: Flyph                     # Drag your Flyph here

var _current_target: float = 1.0
var _tween: Tween = null

func _ready() -> void:
	if player == null:
		return
	# Set initial alpha based on starting position (no pop)
	var start_alpha := 0.0 if player.global_position.y < fade_height else 1.0
	modulate = Color(modulate.r, modulate.g, modulate.b, clampf(start_alpha, 0.0, 1.0))
	_current_target = start_alpha

func _process(_delta: float) -> void:
	if player == null:
		return

	var new_target: float
	if player.global_position.y > fade_height:
		new_target = 0.0
	else:
		new_target = 1.0

	if new_target != _current_target:
		_current_target = new_target
		_start_fade(new_target)

func _start_fade(to_alpha: float) -> void:
	# Kill any existing tween cleanly
	if _tween and _tween.is_valid():
		_tween.kill()

	# Build a single-property tween from current color to target alpha
	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	var from_color := modulate
	var to_color := Color(from_color.r, from_color.g, from_color.b, clampf(to_alpha, 0.0, 1.0))

	_tween.tween_property(self, "modulate", to_color, fade_duration)
