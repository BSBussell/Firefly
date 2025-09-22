extends UiComponent
class_name Meter


@export var increase_speed: float = 10
@export var decrease_speed: float = 20

# Exported textures to compose the meter visuals per level
@export var tex_base: Texture2D
@export var tex_lvl1: Texture2D
@export var tex_lvl2: Texture2D
@export var tex_max: Texture2D


@onready var progress_bar = $Meter
@onready var particle = $Meter/Particle
@onready var fire_lit = $Meter/FireLit
@onready var fire_rumble = $Meter/FireRumble
@onready var rays = $Rays
@onready var brighten = $Control/Brighten
@onready var darkening = $Control2/Darkening

@onready var animation_player = $AnimationPlayer


var actual_score: float = 0
var interpolated_score: float = 0

var played_sound: bool = false

var meter_visible: bool = false

# Track last applied glow level to avoid redundant tint updates
var _last_glow_level: int = -1

# Suppress full-meter FX briefly when flipping layers
var _suppress_full_fx_timer: float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready():
	context.PLAYER.connect_meter(Callable(self, "set_score"))
	
	if context.PLAYER.can_glow():
		meter_visible = true

	animation_player.play("Hide")

	# Neutralize any tinting since we're texture-swapping now
	progress_bar.tint_under = Color(1,1,1,1)
	progress_bar.tint_progress = Color(1,1,1,1)

	# Initialize textures based on current glow level
	_update_textures_for_level()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	

	var multiplier = 1.0
	if interpolated_score > actual_score:
		multiplier = decrease_speed
	else:
		multiplier = increase_speed
	
	interpolated_score = move_toward(interpolated_score, actual_score, delta * multiplier)
	
	progress_bar.value = interpolated_score
	
	var weight: float = interpolated_score/progress_bar.max_value

	# Ensure textures reflect current glow level (may also adjust displayed value for flip illusion)
	_update_textures_for_level()

	# Recompute after potential flip to use displayed value
	var displayed_weight: float = progress_bar.value / progress_bar.max_value
	# Build a cross-level brightness weight so brightness scales with level and progress
	var visual_level: int = clamp(context.PLAYER.get_glow_level(), 0, 2)
	var level_weight: float = clamp((float(visual_level) + displayed_weight) / 3.0, 0.0, 1.0)

	# Tick down any FX suppression window
	if _suppress_full_fx_timer > 0.0:
		_suppress_full_fx_timer = max(_suppress_full_fx_timer - delta, 0.0)
	
	# Handle Animation
	
	if context.PLAYER.can_glow() and not meter_visible:
		meter_visible = true
		animation_player.play("Show")
	elif not context.PLAYER.can_glow() and meter_visible:
		meter_visible = false
		animation_player.play("Hide")
	
	# Setup lights
	brighten.energy = lerpf(0, 1.0, level_weight)
	darkening.energy = lerpf(1.0, 0.0, level_weight)
	
	# Interpolate godrays
	#var color = rays.material.get_shader_parameter("ray_color")
	var cutoff = lerpf(0.23,-0.112, level_weight)
	rays.material.set_shader_parameter("cutoff", cutoff)
	
	if progress_bar.value >= progress_bar.max_value and _suppress_full_fx_timer <= 0.0:
		particle.emitting = true
		# rays.visible = true
		if not played_sound:
			fire_lit.play()
			fire_rumble.play()
			played_sound = true
	else:
		# rays.visible = false
		particle.emitting = false
		played_sound = false
		fire_rumble.stop()
		
	# If we have reached the interpolated score, stop calling the process function
	if interpolated_score == actual_score:
		set_process(false)


func set_score(score: float):
	
	# var adjusted_score: float = (-0.01 * pow(score-100,2) )+100
	# actual_score = min((adjusted_score * 10), 1000)
	actual_score = score

	# If we have a new score, we need to start the process function
	set_process(true)

	# Also refresh textures in case level changed alongside score update
	_update_textures_for_level()

# Adjust the ranges and fits the score inside it to score from jumping around weirdly
func update_range(new_min, new_max):
	var normalized_range = progress_bar.max_value - progress_bar.min_value
	var normalized_actual = (actual_score - progress_bar.min_value) / normalized_range
	var normalized_interp = (interpolated_score - progress_bar.min_value) / normalized_range
	
	var new_range = new_max - new_min
	actual_score = (normalized_actual * new_range) + new_min
	interpolated_score = (normalized_interp * new_range) + new_min
	
	progress_bar.min_value = new_min
	progress_bar.max_value = new_max
	

# Update the TextureProgressBar textures based on current glow level
func _update_textures_for_level():
	if context == null or context.PLAYER == null:
		return

	# Fallbacks: if export vars not set, use current bar textures as sensible defaults
	if tex_base == null:
		tex_base = progress_bar.texture_under
	if tex_lvl1 == null:
		tex_lvl1 = progress_bar.texture_progress
	if tex_lvl2 == null:
		tex_lvl2 = tex_lvl1
	if tex_max == null:
		tex_max = tex_lvl2

	var level: int = context.PLAYER.get_glow_level()
	if level == _last_glow_level:
		return

	var under_tex: Texture2D = tex_base
	var prog_tex: Texture2D = tex_lvl1

	# Determine direction of level change (skip on first initialization)
	var has_prev: bool = _last_glow_level != -1
	var direction: int = 0
	if has_prev:
		direction = sign(level - _last_glow_level)

	match level:
		0:
			under_tex = tex_base
			prog_tex = tex_lvl1
		1:
			under_tex = tex_lvl1
			prog_tex = tex_lvl2
		_:
			# Level 2 and beyond
			under_tex = tex_lvl2
			prog_tex = tex_max

	progress_bar.texture_under = under_tex
	progress_bar.texture_progress = prog_tex

	# Seamless layered flip illusion
	if has_prev and direction != 0:
		var target_score: float = float(context.PLAYER.get_glow_score())
		if direction > 0:
			# Promoted: show 0 on new layer, then rise to actual
			interpolated_score = progress_bar.min_value
			progress_bar.value = interpolated_score
			actual_score = target_score
			set_process(true)
		else:
			# Demoted: show 100 on new layer, then fall to actual
			interpolated_score = progress_bar.max_value
			progress_bar.value = interpolated_score
			actual_score = target_score
			set_process(true)
			# Prevent full-meter FX from triggering on this synthetic 100%
			_suppress_full_fx_timer = 0.08

	_last_glow_level = level
