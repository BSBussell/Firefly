extends Node
class_name InputManager

signal device_changed(name: String, is_gamepad: bool)
signal action_set_changed(name: String)

const NativeInputBackendScript: Script = preload("res://Scripts/Globals/NativeInputBackend.gd")
const SteamInputBackendScript: Script = preload("res://Scripts/Globals/SteamInputBackend.gd")

var _backend: InputBackend
var _using_steam_backend: bool = false
var _active_action_set: StringName = &"default"
var _current_device_name: String = "keyboard_mouse"
var _current_device_is_gamepad: bool = false

func _ready() -> void:
	set_process_input(true)
	set_process(true)
	_backend = _create_backend()
	var steam_manager = _get_steam_manager()
	if steam_manager:
		if not steam_manager.is_connected("steam_ready", Callable(self, "_on_steam_ready")):
			steam_manager.connect("steam_ready", Callable(self, "_on_steam_ready"), CONNECT_ONE_SHOT)
		if not steam_manager.is_connected("steam_failed", Callable(self, "_on_steam_failed")):
			steam_manager.connect("steam_failed", Callable(self, "_on_steam_failed"), CONNECT_ONE_SHOT)

func get_actions() -> Array[StringName]:
	return _backend.get_actions()

func is_down(action: StringName) -> bool:
	return _backend.is_down(action)

func was_pressed(action: StringName) -> bool:
	return _backend.was_pressed(action)

func was_released(action: StringName) -> bool:
	return _backend.was_released(action)

func axis(action_name: StringName = &"move") -> Vector2:
	return _backend.axis(action_name)

func set_action_set(action_set: StringName) -> void:
	if action_set == _active_action_set:
		return

	_active_action_set = action_set
	_backend.set_action_set(action_set)
	emit_signal("action_set_changed", String(action_set))

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

func _process(delta: float) -> void:
	if _backend:
		_backend.update(delta)

func _input(event: InputEvent) -> void:
	if not _should_consider_event(event):
		return

	var info = _derive_device_info(event)
	if info.is_empty():
		return

	var device_name: String = info["name"]
	var is_gamepad: bool = info["is_gamepad"]

	if device_name == _current_device_name and is_gamepad == _current_device_is_gamepad:
		return

	_current_device_name = device_name
	_current_device_is_gamepad = is_gamepad
	emit_signal("device_changed", device_name, is_gamepad)

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

func _create_backend() -> InputBackend:
	var steam_manager: Steam_Manager = _get_steam_manager()
	var steam_available: bool = Engine.has_singleton("Steam") and steam_manager != null and steam_manager.is_ready()
	if steam_available:
		_using_steam_backend = true
		var steam_backend: InputBackend = SteamInputBackendScript.new()
		steam_backend.set_action_set(_active_action_set)
		return steam_backend
	_using_steam_backend = false
	var native_backend: InputBackend = NativeInputBackendScript.new()
	native_backend.set_action_set(_active_action_set)
	return native_backend

func _switch_backend(new_backend: InputBackend) -> void:
	if new_backend == null:
		return
	_backend = new_backend
	_backend.set_action_set(_active_action_set)
	_current_device_name = "keyboard_mouse"
	_current_device_is_gamepad = false
	_backend.update(0.0)

func _on_steam_ready() -> void:
	if _using_steam_backend or not Engine.has_singleton("Steam"):
		return
	_using_steam_backend = true
	_switch_backend(SteamInputBackendScript.new())

func _on_steam_failed(_error: String) -> void:
	if not _using_steam_backend:
		return
	_using_steam_backend = false
	_switch_backend(NativeInputBackendScript.new())

func _get_steam_manager() -> Steam_Manager:
	var main_loop: MainLoop = Engine.get_main_loop()
	if main_loop is SceneTree:
		var scene_tree: SceneTree = main_loop
		var root: Node = scene_tree.root
		return root.get_node_or_null("/root/_steam_manager") as Steam_Manager
	return null
