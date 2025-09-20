extends Line2D
class_name Trail

@export var follow: Node2D
@export var max_points: int = 64
@export var min_distance: float = 3.0
@export var offset: Vector2 = Vector2.ZERO
@export var length: int = 10                    # base point count at 60 FPS

# --- Width pulsing params ---
@export var pulse_enabled: bool = true
@export var base_width: float = 6.0              # average width
@export var pulse_amplitude: float = 0.5         # 0.0..1.0 (fraction of base)
@export var pulse_hz: float = 2.0                # pulses per second
@export var pulse_phase: float = 0.0             # radians; shift the wave if you want
@export var min_width: float = 0.5               # safety floor

# When true, render in world/canvas space and ignore parent transforms and opacity.
# When false, remain under parent so parent opacity/modulate can affect this trail.
@export var use_top_level: bool = true

var _time: float = 0.0
var _fps_adjusted_length: int = 10
var _last_anchor: Vector2 = Vector2.ZERO
var _has_anchor: bool = false

func _ready() -> void:
	# Optionally draw in world/canvas space, not relative to parent.
	set_as_top_level(use_top_level)
	if use_top_level:
		global_position = Vector2.ZERO
		global_rotation = 0.0
		global_scale = Vector2.ONE

	clear_points()
	_has_anchor = false

	if is_instance_valid(follow):
		var p0: Vector2 = follow.global_position + offset
		# Prime with two identical points at the FRONT so index 0 is the head.
		add_point(p0, 0)
		add_point(p0, 0)
		_last_anchor = p0
		_has_anchor = true

	_update_width(0.0)

func _process(delta: float) -> void:
	if !is_instance_valid(follow):
		return

	# Keep this node’s own transform neutral every frame when top-level.
	if use_top_level:
		global_position = Vector2.ZERO
		global_rotation = 0.0
		global_scale = Vector2.ONE

	var p: Vector2 = follow.global_position + offset

	if get_point_count() == 0:
		add_point(p, 0)
		add_point(p, 0)
		_last_anchor = p
		_has_anchor = true
	else:
		if !_has_anchor:
			_last_anchor = get_point_position(0)
			_has_anchor = true
		var should_add: bool = min_distance <= 0.0
		if !should_add and _has_anchor:
			should_add = _last_anchor.distance_to(p) >= min_distance
		if should_add:
			add_point(p, 0)
			_last_anchor = p
		else:
			set_point_position(0, p)

	# FPS-scaled target length (match player trail)
	_fps_adjusted_length = int(max(length * (Engine.get_frames_per_second() / 60.0), 0.0))
	var target_length: int = _fps_adjusted_length
	if max_points > 0:
		target_length = min(target_length, max_points)

	# Clamp length by trimming from the TAIL (remove from end)
	while get_point_count() > target_length:
		remove_point(get_point_count() - 1)

	if get_point_count() == 0:
		_has_anchor = false

	# Animate width
	_time += delta
	_update_width(_time)

func _update_width(t: float) -> void:
	if !pulse_enabled:
		width = max(base_width, min_width)
		return
	var amp: float = clamp(pulse_amplitude, 0.0, 1.0)
	var w: float = base_width * (1.0 + amp * sin(TAU * pulse_hz * t + pulse_phase))
	width = max(w, min_width)
