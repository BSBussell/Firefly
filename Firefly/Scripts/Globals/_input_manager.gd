extends Node
class_name InputManager

signal device_changed(name: String, is_gamepad: bool)
signal action_set_changed(name: String)

const NativeInputBackendScript := preload("res://Scripts/Globals/NativeInputBackend.gd")

var _backend: InputBackend
var _active_action_set: StringName = &"default"
var _current_device_name: String = "keyboard_mouse"
var _current_device_is_gamepad: bool = false

func _ready() -> void:
	_backend = NativeInputBackendScript.new()
	set_process_input(true)

func get_actions() -> Array[StringName]:
	return _backend.get_actions()

func is_down(action: StringName) -> bool:
	return _backend.is_down(action)

func was_pressed(action: StringName) -> bool:
	return _backend.was_pressed(action)

func was_released(action: StringName) -> bool:
	return _backend.was_released(action)

func axis(name: StringName = &"move") -> Vector2:
	return _backend.axis(name)

func set_action_set(name: StringName) -> void:
	if name == _active_action_set:
		return

	_active_action_set = name
	_backend.set_action_set(name)
	emit_signal("action_set_changed", String(name))

func get_glyph_paths_for(action: StringName) -> Array[String]:
	return _backend.get_glyph_paths_for(action)

func get_bindings(action: StringName) -> Array[BindingModel]:
	return _backend.get_bindings(action)

func add_binding(action: StringName, event: InputEvent) -> bool:
	return _backend.add_binding(action, event)

func remove_binding(action: StringName, binding_id: String) -> bool:
	return _backend.remove_binding(action, binding_id)

func reset_keyboard_defaults() -> void:
	_backend.reset_keyboard_defaults()

func open_controller_binding_panel() -> bool:
	return _backend.open_controller_binding_panel()

func is_steam_active() -> bool:
	return _backend.is_steam_active()

func _input(event: InputEvent) -> void:
	if not _should_consider_event(event):
		return

	var info := _derive_device_info(event)
	if info.is_empty():
		return

	var name: String = info["name"]
	var is_gamepad: bool = info["is_gamepad"]

	if name == _current_device_name and is_gamepad == _current_device_is_gamepad:
		return

	_current_device_name = name
	_current_device_is_gamepad = is_gamepad
	emit_signal("device_changed", name, is_gamepad)

func _should_consider_event(event: InputEvent) -> bool:
	if event is InputEventJoypadMotion:
		return abs((event as InputEventJoypadMotion).axis_value) > 0.2
	if event is InputEventJoypadButton:
		return (event as InputEventJoypadButton).pressed
	if event is InputEventKey:
		return (event as InputEventKey).pressed and not (event as InputEventKey).echo
	if event is InputEventMouseButton:
		return (event as InputEventMouseButton).pressed
	if event is InputEventMouseMotion:
		return (event as InputEventMouseMotion).relative.length_squared() > 0.0
	if event is InputEventAction:
		return (event as InputEventAction).pressed
	return false

func _derive_device_info(event: InputEvent) -> Dictionary:
	var info: Dictionary = {}
	if event is InputEventJoypadButton:
		info["name"] = "gamepad_%d" % [(event as InputEventJoypadButton).device]
		info["is_gamepad"] = true
	elif event is InputEventJoypadMotion:
		info["name"] = "gamepad_%d" % [(event as InputEventJoypadMotion).device]
		info["is_gamepad"] = true
	elif event is InputEventKey:
		info["name"] = "keyboard"
		info["is_gamepad"] = false
	elif event is InputEventMouseButton or event is InputEventMouseMotion:
		info["name"] = "mouse"
		info["is_gamepad"] = false
	elif event is InputEventAction:
		info["name"] = "action"
		info["is_gamepad"] = false
	return info
