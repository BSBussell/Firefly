# ParallaxAnchor.gd (Godot 4.x)
extends Node2D

## 1. Set this to your Camera2D (or leave blank to auto-grab the current one)
@export var camera_path: PlayerCam

## 2. Parallax factor: 1.0 = moves like normal world objects (foreground),
##    0.0 = sticks to screen (UI), 0.5 = classic midground drift, etc.
@export_range(0.0, 5.0, 0.01) var factor: float = 0.5

## 3. Base world position: where this emitter "really" lives on the map.
##    If use_current_as_base is true, we'll capture your current position in _ready().
@export var base_position: Vector2
@export var use_current_as_base := true

var _cam: PlayerCam
var _cam_base_pos: Vector2 = Vector2.ZERO

func _ready() -> void:
	
	_cam = camera_path
	if use_current_as_base:
		base_position = global_position
	_cam_base_pos = _cam.global_position if _cam else Vector2.ZERO
	set_process(true)

func _process(_dt: float) -> void:
	if _cam == null:
		return
	# Move this node by a fraction of the camera's displacement since we anchored it.
	# factor = 1.0  -> stay at base_position (normal world behavior)
	# factor = 0.0  -> track camera fully (screen space)
	var cam_delta := _cam.global_position - _cam_base_pos
	global_position = base_position + cam_delta * (1.0 - factor)
