extends Node2D

var _trails: Array[Line2D] = []
var _trail_tween: Tween = null

var _prepared: bool = false
var _initial_trails_alpha: float = 1.0
var _initial_visual_alpha: float = 1.0

func prepare_for_fade_in(trails_alpha: float = 0.0, visual_alpha: float = 0.0) -> void:
	_prepared = true
	_initial_trails_alpha = trails_alpha
	_initial_visual_alpha = visual_alpha

func _ready() -> void:
	_collect_trails()
	if _prepared:
		# Apply initial invisible state before first draw
		self.modulate.a = _initial_visual_alpha
		set_trails_alpha(_initial_trails_alpha)

func _collect_trails() -> void:
	_trails.clear()
	for child in get_children():
		if child is Line2D:
			_trails.append(child)

func _ensure_trails() -> void:
	if _trails.is_empty():
		_collect_trails()

func set_trails_alpha(alpha: float) -> void:
	_ensure_trails()
	for t in _trails:
		var m := t.modulate
		m.a = alpha
		t.modulate = m

func fade_trails_to(alpha: float, duration: float) -> void:
	_ensure_trails()
	if _trail_tween and is_instance_valid(_trail_tween):
		_trail_tween.kill()
	_trail_tween = create_tween()
	for t in _trails:
		_trail_tween.parallel().tween_property(t, "modulate:a", alpha, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
