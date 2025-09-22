extends InputBackend
class_name SteamInputBackend

const DEBUG_STEAM_INPUT: bool = true
const COMBINE_STEAM_AND_NATIVE_AXES: bool = true
const NativeInputBackendScript: GDScript = preload("res://Scripts/Globals/NativeInputBackend.gd")
const ACTION_SET_GAMEPLAY: StringName = &"gameplay"
const ACTION_SET_MENU: StringName = &"menu"
const DEFAULT_ACTION_SET: StringName = &"default"
const MOVE_ACTION: StringName = &"move"

var _steam_api: Object = null
var _steam_manager: Steam_Manager = null
var _native_backend: NativeInputBackend = NativeInputBackendScript.new()

var _actions: Array[StringName] = []
var _action_set_handles: Dictionary = {}
var _digital_handles: Dictionary = {}
var _analog_handle: int = 0
var _controllers: Array[int] = []
var _primary_controller: int = 0
var _current_digital_states: Dictionary = {}
var _previous_digital_states: Dictionary = {}
var _current_axis: Vector2 = Vector2.ZERO
var _current_action_set: StringName = DEFAULT_ACTION_SET
var _pending_action_set_change: bool = false
var _initialized: bool = false

var _got_handles: bool = false
# var _game_action_set: int = 0

func _init() -> void:
	_actions = _native_backend.get_actions()
	_steam_api = _obtain_steam_singleton()
	_steam_manager = _obtain_steam_manager()
	if _steam_manager != null and _steam_manager.is_ready():
		_initialize()
	elif _steam_manager != null:
		if not _steam_manager.is_connected("steam_ready", Callable(self, "_on_steam_ready")):
			_steam_manager.connect("steam_ready", Callable(self, "_on_steam_ready"), CONNECT_ONE_SHOT)

func get_actions() -> Array[StringName]:
	return _native_backend.get_actions()

func is_down(action: StringName) -> bool:
	if _initialized and _digital_handles.has(action):
		return _steam_action_down(action)
	return _native_backend.is_down(action)

func was_pressed(action: StringName) -> bool:
	if _initialized and _digital_handles.has(action):
		return _steam_action_pressed(action)
	return _native_backend.was_pressed(action)

func was_released(action: StringName) -> bool:
	if _initialized and _digital_handles.has(action):
		return _steam_action_released(action)
	return _native_backend.was_released(action)

func axis(name: StringName = &"move") -> Vector2:
	var native_axis: Vector2 = _native_backend.axis(name)
	if name != MOVE_ACTION or not _initialized or _analog_handle == 0:
		return native_axis
	var steam_axis: Vector2 = _current_axis
	if steam_axis.length_squared() == 0.0:
		return native_axis
	if not COMBINE_STEAM_AND_NATIVE_AXES:
		return steam_axis
	var combined: Vector2 = native_axis + steam_axis
	combined.x = clamp(combined.x, -1.0, 1.0)
	combined.y = clamp(combined.y, -1.0, 1.0)
	return combined

func set_action_set(name: StringName) -> void:
	# Force Steam Input to only ever use the gameplay set.
	_current_action_set = ACTION_SET_GAMEPLAY
	_pending_action_set_change = true
	# Native backend can still observe the requested name if needed.
	_native_backend.set_action_set(name)

func get_glyph_paths_for(action: StringName) -> Array[String]:
	return _collect_glyphs(action)

func get_bindings(action: StringName) -> Array[BindingModel]:
	var bindings: Array[BindingModel] = _native_backend.get_bindings(action)
	var glyphs = _collect_glyphs(action)
	if glyphs.size() == 0:
		if _initialized and _digital_handles.has(action):
			var binding_id = "steam:%s" % [String(action)]
			bindings.append(InputBackend.build_binding_model(action, null, binding_id, StringName("steam"), "Steam Input"))
		return bindings
	for index in glyphs.size():
		var glyph_path: String = glyphs[index]
		var binding_id = "steam:%s:%d" % [String(action), index]
		bindings.append(InputBackend.build_binding_model(action, null, binding_id, StringName("steam"), glyph_path))
	return bindings

func add_binding(action: StringName, event: InputEvent) -> bool:
	return _native_backend.add_binding(action, event)

func remove_binding(action: StringName, binding_id: String) -> bool:
	return _native_backend.remove_binding(action, binding_id)

func reset_keyboard_defaults() -> void:
	_native_backend.reset_keyboard_defaults()

func open_controller_binding_panel() -> bool:
	if not _initialized or _primary_controller == 0 or _steam_api == null:
		return false
	if "showBindingPanel" in _steam_api:
		return bool(_steam_api.showBindingPanel(_primary_controller))
	return false

func is_steam_active() -> bool:
	return _initialized

func update(delta: float) -> void:
	_native_backend.update(delta)
	_run_steam_frame()
	if not _initialized:
		return
	_refresh_controllers()
	_apply_action_set_if_needed()
	_poll_inputs()

func _initialize() -> void:
	if _steam_api == null:
		return

	var input_ok := true
	if "inputInit" in _steam_api:
		input_ok = bool(_steam_api.inputInit())
	if not input_ok:
		push_warning("Steam Input inputInit() failed; using native input.")
		if DEBUG_STEAM_INPUT:
			print("Steam Input: inputInit() returned false")
		return
	if "enableDeviceCallbacks" in _steam_api:
		_steam_api.enableDeviceCallbacks()

	if not _steam_api.is_connected("input_device_connected", Callable(self, "_on_steam_input_device_connected")):
		_steam_api.connect("input_device_connected", Callable(self, "_on_steam_input_device_connected"))
	if not _steam_api.is_connected("input_device_disconnected", Callable(self, "_on_steam_input_device_disconnected")):
		_steam_api.connect("input_device_disconnected", Callable(self, "_on_steam_input_device_disconnected"))

	_refresh_controllers()

	if _controllers.is_empty():
		# Defer full init until a controller connects
		if DEBUG_STEAM_INPUT:
			print("Steam Input: waiting for controller connection before caching handles")
		return

	_cache_action_sets()
	_cache_action_handles()

	var gameplay_handle: int = _resolve_action_set_handle(ACTION_SET_GAMEPLAY)
	if gameplay_handle == 0:
		push_warning("Steam Input gameplay action set handle not resolved; using native input.")
		if DEBUG_STEAM_INPUT:
			print("Steam Input: invalid gameplay handle=", gameplay_handle)
		return
	_got_handles = true
	_initialized = true
	set_action_set(ACTION_SET_GAMEPLAY)
	_apply_action_set_if_needed()
	if DEBUG_STEAM_INPUT:
		print("Steam Input initialized. Controllers=", _controllers)

func _run_steam_frame() -> void:
	if _steam_api and "runFrame" in _steam_api:
		_steam_api.runFrame()

func _refresh_controllers() -> void:
	if _steam_api == null or not "getConnectedControllers" in _steam_api:
		_controllers = []
		_primary_controller = 0
		return
	var controllers_variant: Array = _steam_api.getConnectedControllers()
	var new_controllers: Array[int] = []
	for controller_variant in controllers_variant:
		new_controllers.append(int(controller_variant))
	var controllers_changed: bool = new_controllers != _controllers
	_controllers = new_controllers
	if _controllers.is_empty():
		_primary_controller = 0
	elif _primary_controller == 0 or not _controllers.has(_primary_controller):
		_primary_controller = _controllers[0]
	if _initialized:
		_apply_action_set_if_needed()
	if DEBUG_STEAM_INPUT and controllers_changed:
		print("Steam Input controllers:", _controllers)

func _apply_action_set_if_needed() -> void:
	if not _pending_action_set_change:
		return
	_pending_action_set_change = false
	# Always resolve to gameplay; fall back if needed.
	var handle: int = _resolve_action_set_handle(ACTION_SET_GAMEPLAY)
	if handle == 0 or _steam_api == null or not "activateActionSet" in _steam_api:
		return
	for controller in _controllers:
		_steam_api.activateActionSet(controller, handle)
	if DEBUG_STEAM_INPUT:
		print("Steam Input: activated set ", String(ACTION_SET_GAMEPLAY), " handle=", handle)

func _poll_inputs() -> void:
	var new_states: Dictionary = {}
	for action in _digital_handles.keys():
		var handle: int = _digital_handles[action]
		var controller_states: Dictionary = {}
		for controller in _controllers:
			var pressed: bool = _read_digital_state(controller, handle)
			controller_states[controller] = pressed
			if pressed and not _get_previous_state(action, controller):
				if _primary_controller != controller:
					_primary_controller = controller
		new_states[action] = controller_states
	_previous_digital_states = _current_digital_states.duplicate(true)
	_current_digital_states = new_states
	_update_axis_state()

func _update_axis_state() -> void:
	_current_axis = Vector2.ZERO
	if _primary_controller == 0 or _analog_handle == 0 or _steam_api == null:
		return
	if not "getAnalogActionData" in _steam_api:
		return
	var data: Variant = _steam_api.call("getAnalogActionData", _primary_controller, _analog_handle)
	if typeof(data) != TYPE_DICTIONARY:
		return
	var active: bool = bool(data.get("active", data.get("bActive", false)))
	if not active:
		return
	var x: float = float(data.get("x", 0.0))
	var y: float = float(data.get("y", 0.0))
	var new_axis: Vector2 = Vector2(x, y)
	if new_axis.length_squared() > 0.0:
		_current_axis = new_axis

func _cache_action_sets() -> void:
	_action_set_handles.clear()
	if _steam_api == null or not "getActionSetHandle" in _steam_api:
		return
	var gameplay_handle_variant = _steam_api.call("getActionSetHandle", String(ACTION_SET_GAMEPLAY))
	var menu_handle_variant = _steam_api.call("getActionSetHandle", String(ACTION_SET_MENU))
	var gameplay_handle: int = int(gameplay_handle_variant)
	var menu_handle: int = int(menu_handle_variant)
	if gameplay_handle != 0:
		_action_set_handles[ACTION_SET_GAMEPLAY] = gameplay_handle
		_action_set_handles[DEFAULT_ACTION_SET] = gameplay_handle
	if menu_handle != 0:
		_action_set_handles[ACTION_SET_MENU] = menu_handle
	if DEBUG_STEAM_INPUT:
		print("Steam Input: cached action sets gameplay=", gameplay_handle, " menu=", menu_handle)

func _cache_action_handles() -> void:
	_digital_handles.clear()
	_analog_handle = 0
	if _steam_api == null:
		return
	_actions = _native_backend.get_actions()
	var has_digital: bool = "getDigitalActionHandle" in _steam_api
	var has_analog: bool = "getAnalogActionHandle" in _steam_api
	for action in _actions:
		var action_name: String = String(action)
		if has_digital:
			var digital_handle_variant = _steam_api.call("getDigitalActionHandle", action_name)
			var digital_handle: int = int(digital_handle_variant)
			if digital_handle != 0:
				_digital_handles[action] = digital_handle
		if has_analog and action == MOVE_ACTION:
			var analog_handle_variant = _steam_api.call("getAnalogActionHandle", action_name)
			var analog_handle: int = int(analog_handle_variant)
			if analog_handle != 0:
				_analog_handle = analog_handle
		if has_analog and _analog_handle == 0:
			var analog_handle_fallback_variant = _steam_api.call("getAnalogActionHandle", String(MOVE_ACTION))
			var analog_handle_fallback: int = int(analog_handle_fallback_variant)
			if analog_handle_fallback != 0:
				_analog_handle = analog_handle_fallback
	
	_reset_digital_state_cache()
	_got_handles = true
	if DEBUG_STEAM_INPUT:
		print("Steam Input: cached digital actions=", _digital_handles.keys(), " analog_move=", _analog_handle)

func _reset_digital_state_cache() -> void:
	_current_digital_states.clear()
	_previous_digital_states.clear()
	for action in _digital_handles.keys():
		_current_digital_states[action] = {}
		_previous_digital_states[action] = {}

func _steam_action_down(action: StringName) -> bool:
	if not _initialized:
		return false
	var states_variant: Variant = _current_digital_states.get(action, null)
	if states_variant is Dictionary:
		var states: Dictionary = states_variant
		if _primary_controller != 0 and states.has(_primary_controller):
			return bool(states[_primary_controller])
		for value in states.values():
			if bool(value):
				return true
	return false

func _steam_action_pressed(action: StringName) -> bool:
	if not _initialized:
		return false
	return _digital_state_transition(action, true)

func _steam_action_released(action: StringName) -> bool:
	if not _initialized:
		return false
	return _digital_state_transition(action, false)

func _digital_state_transition(action: StringName, rising: bool) -> bool:
	var current_variant: Variant = _current_digital_states.get(action, null)
	var previous_variant: Variant = _previous_digital_states.get(action, {})
	if current_variant is Dictionary:
		var current_states: Dictionary = current_variant
		var previous_states: Dictionary = previous_variant if previous_variant is Dictionary else {}
		for controller in current_states.keys():
			var current: bool = bool(current_states[controller])
			var previous: bool = bool(previous_states.get(controller, false))
			if rising and current and not previous:
				return true
			if not rising and not current and previous:
				return true
	return false

func _get_previous_state(action: StringName, controller: int) -> bool:
	var states_variant: Variant = _current_digital_states.get(action, null)
	if states_variant is Dictionary:
		var states: Dictionary = states_variant
		if states.has(controller):
			return bool(states[controller])
	return false

func _read_digital_state(controller: int, handle: int) -> bool:
	if _steam_api == null or not "getDigitalActionData" in _steam_api:
		return false
	var data: Variant = _steam_api.call("getDigitalActionData", controller, handle)
	if typeof(data) != TYPE_DICTIONARY:
		return false
	var active: bool = bool(data.get("active", data.get("bActive", false)))
	if not active:
		return false
	return bool(data.get("state", data.get("bState", false)))

func _collect_glyphs(action: StringName) -> Array[String]:
	var glyphs: Array[String] = []
	if not _initialized or _steam_api == null:
		return glyphs
	var origins: Array = []
	var action_set_handle = _resolve_action_set_handle(_current_action_set)
	if action_set_handle == 0:
		action_set_handle = _resolve_action_set_handle(ACTION_SET_GAMEPLAY)
	if _primary_controller == 0 or action_set_handle == 0:
		return glyphs
	if _digital_handles.has(action) and "getDigitalActionOrigins" in _steam_api:
		origins = _steam_api.getDigitalActionOrigins(_primary_controller, action_set_handle, _digital_handles[action])
	elif action == MOVE_ACTION and _analog_handle != 0 and "getAnalogActionOrigins" in _steam_api:
		origins = _steam_api.getAnalogActionOrigins(_primary_controller, action_set_handle, _analog_handle)
	for origin in origins:
		var glyph_path = _glyph_for_origin(int(origin))
		if glyph_path.is_empty():
			continue
		glyphs.append(glyph_path)
	return glyphs

func _glyph_for_origin(origin: int) -> String:
	if _steam_api == null:
		return ""
	if "getGlyphForActionOrigin" in _steam_api:
		return String(_steam_api.getGlyphForActionOrigin(origin))
	if "getGlyphPNGForActionOrigin" in _steam_api:
		return String(_steam_api.getGlyphPNGForActionOrigin(origin, 0, 0))
	return ""

func _resolve_action_set_handle(name: StringName) -> int:
	var lookup_name = name
	if lookup_name == DEFAULT_ACTION_SET:
		lookup_name = ACTION_SET_GAMEPLAY
	if _action_set_handles.has(lookup_name):
		return int(_action_set_handles[lookup_name])
	return 0

func _obtain_steam_singleton() -> Object:
	return Engine.get_singleton("Steam") if Engine.has_singleton("Steam") else null

func _obtain_steam_manager() -> Steam_Manager:
	var main_loop: MainLoop = Engine.get_main_loop()
	if main_loop is SceneTree:
		var scene_tree: SceneTree = main_loop
		var root: Node = scene_tree.root
		return root.get_node_or_null("/root/_steam_manager") as Steam_Manager
	return null

func _on_steam_ready() -> void:
	if _initialized or not Engine.has_singleton("Steam"):
		return
	_initialize()

func _on_steam_input_device_connected(input_handle: int) -> void:
	if DEBUG_STEAM_INPUT:
		print("Steam Input: device connected ", input_handle)
	_refresh_controllers()
	if not _got_handles:
		_cache_action_sets()
		_cache_action_handles()
		var gameplay_handle: int = _resolve_action_set_handle(ACTION_SET_GAMEPLAY)
		var menu_handle: int = _resolve_action_set_handle(ACTION_SET_MENU)
		if gameplay_handle != 0 and menu_handle != 0:
			_got_handles = true
			_initialized = true
	_apply_action_set_if_needed()

func _on_steam_input_device_disconnected(input_handle: int) -> void:
	if DEBUG_STEAM_INPUT:
		print("Steam Input: device disconnected ", input_handle)
	_refresh_controllers()
	if _controllers.is_empty():
		_primary_controller = 0
		_initialized = false
		_got_handles = false
