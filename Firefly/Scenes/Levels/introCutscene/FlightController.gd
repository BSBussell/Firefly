extends Node2D

@export var pops: Node2D
@export var flyph: Node2D

# sine states
var pops_movin: bool = false
var pops_amplitude: float = 0.0
var pops_wavelength: float = 0.0

var flyph_movin: bool = false
var flyph_amplitude: float = 0.0
var flyph_wavelength: float = 0.0

# local anchors / targets (relative to parent a.k.a. camera)
var pops_anchor: Vector2 = Vector2.ZERO
var flyph_anchor: Vector2 = Vector2.ZERO
var pops_target: Vector2 = Vector2.ZERO
var flyph_target: Vector2 = Vector2.ZERO
var pops_speed: float = 1000.0   # px/sec
var flyph_speed: float = 1000.0  # px/sec

var counter: float = 0.0

func _ready() -> void:
	if pops:
		pops_anchor = pops.position
		pops_target = pops_anchor
	if flyph:
		flyph_anchor = flyph.position
		flyph_target = flyph_anchor

func _process(delta: float) -> void:
	# 1) move anchors toward LOCAL targets
	if pops and pops_speed > 0.0:
		pops_anchor = pops_anchor.move_toward(pops_target, pops_speed * delta)
		

	if flyph and flyph_speed > 0.0:
		flyph_anchor = flyph_anchor.move_toward(flyph_target, flyph_speed * delta)
		

	# 2) sine offsets (local Y)
	var pops_off_y: float = pops_amplitude * sin(pops_wavelength * counter) \
		if pops_movin and pops_amplitude != 0.0 and pops_wavelength != 0.0 else 0.0
	var flyph_off_y: float = flyph_amplitude * sin(flyph_wavelength * counter) \
		if flyph_movin and flyph_amplitude != 0.0 and flyph_wavelength != 0.0 else 0.0

	# 3) apply anchor + offset (still LOCAL)
	if pops:
		pops.position = Vector2(pops_anchor.x, pops_anchor.y + pops_off_y)
	if flyph:
		flyph.position = Vector2(flyph_anchor.x, flyph_anchor.y + flyph_off_y)

	counter += delta

# -- sine API ------------------------------------------------

func activate_pops_sine(amp: float, wavelength: float) -> void:
	pops_movin = true
	pops_amplitude = amp
	pops_wavelength = wavelength

func activate_flyph_sine(amp: float, wavelength: float) -> void:
	flyph_movin = true
	flyph_amplitude = amp
	flyph_wavelength = wavelength

func deactivate_pops_sine(reset: bool = true) -> void:
	pops_movin = false
	if reset and pops:
		pops.position = pops_anchor

func deactivate_flyph_sine(reset: bool = true) -> void:
	flyph_movin = false
	if reset and flyph:
		flyph.position = flyph_anchor

# -- movement API (LOCAL) ------------------------------------

func move_pops_towards_local(target_local: Vector2, speed: float) -> void:
	pops_target = target_local
	pops_speed = max(speed, 0.0)

func move_pops_towards(target_local: Vector2, speed: float) -> void:
	move_pops_towards_local(target_local, speed)

func move_flyph_towards_local(target_local: Vector2, speed: float) -> void:
	flyph_target = target_local
	flyph_speed = max(speed, 0.0)

func move_flyph_towards(target_local: Vector2, speed: float) -> void:
	move_flyph_towards_local(target_local, speed)

func move_pops_by_local(offset: Vector2, speed: float) -> void:
	move_pops_towards_local(pops_anchor + offset, speed)

func move_flyph_by_local(offset: Vector2, speed: float) -> void:
	move_flyph_towards_local(flyph_anchor + offset, speed)


# if something else (AnimationPlayer/teleport) changed their local position,
# call this to adopt current local as the new anchor/target before resuming sine
func reanchor_now() -> void:
	if pops:
		pops_anchor = pops.position
		pops_target = pops_anchor
	if flyph:
		flyph_anchor = flyph.position
		flyph_target = flyph_anchor
