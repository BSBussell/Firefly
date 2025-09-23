extends InputBackend
class_name SteamInputBackend

const LOG_CONTEXT: String = "SteamInputBackend"
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
# Logger cache and diagnostics guards
var _logger_ref: Logger = null
var _logged_missing_digital_api: bool = false
var _logged_invalid_digital_data: bool = false
var _logged_missing_analog_api: bool = false
var _logged_invalid_analog_data: bool = false
# var _game_action_set: int = 0

func _get_logger() -> Logger:
	if _logger_ref != null:
		return _logger_ref
	var main_loop: MainLoop = Engine.get_main_loop()
	if main_loop is SceneTree:
		var scene_tree: SceneTree = main_loop
		var root: Node = scene_tree.root
		_logger_ref = root.get_node_or_null("/root/_logger") as Logger
	return _logger_ref

func _ensure_logging_enabled() -> void:
	var logger: Logger = _get_logger()
	if logger == null:
		return
	if not logger.log_calls:
		logger.log_calls = true
		logger.info("[%s] Enabled log_calls" % LOG_CONTEXT)

func _log(message: String, level: String = "debug") -> void:
	var logger: Logger = _get_logger()
	if logger == null:
		return
	var formatted: String = "[%s] %s" % [LOG_CONTEXT, message]
	match level:
		"info":
			logger.info(formatted)
		"warning":
			logger.warning(formatted)
		"error":
			logger.error(formatted)
		_:
			logger.debug(formatted)

func _describe(value: Variant) -> String:
	return str(value)

func _init() -> void:
	_ensure_logging_enabled()
	_actions = _native_backend.get_actions()
	_log("_init with actions=%s" % [_describe(_actions)], "info")
	_steam_api = _obtain_steam_singleton()
	if _steam_api == null:
		_log("Steam singleton unavailable; falling back to native input", "warning")
	_steam_manager = _obtain_steam_manager()
	if _steam_manager == null:
		_log("Steam manager not found in scene tree", "warning")
	if _steam_manager != null and _steam_manager.is_ready():
		_log("Steam manager ready during init", "info")
		_initialize()
	elif _steam_manager != null:
		if not _steam_manager.is_connected("steam_ready", Callable(self, "_on_steam_ready")):
			_log("Steam manager not ready; connecting steam_ready signal", "debug")
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
		_log("Cannot initialize Steam Input; Steam singleton missing", "warning")
		return
	_logged_missing_digital_api = false
	_logged_invalid_digital_data = false
	_logged_missing_analog_api = false
	_logged_invalid_analog_data = false

	_log("Beginning Steam Input initialization", "info")
	var input_ok := true
	if "inputInit" in _steam_api:
		input_ok = bool(_steam_api.inputInit())
	if not input_ok:
		push_warning("Steam Input inputInit() failed; using native input.")
		_log("Steam Input inputInit returned false", "error")
		if DEBUG_STEAM_INPUT:
			print("Steam Input: inputInit() returned false")
		return
	if "enableDeviceCallbacks" in _steam_api:
		_steam_api.enableDeviceCallbacks()
		_log("Enabled Steam Input device callbacks", "debug")

	if not _steam_api.is_connected("input_device_connected", Callable(self, "_on_steam_input_device_connected")):
		_steam_api.connect("input_device_connected", Callable(self, "_on_steam_input_device_connected"))
		_log("Connected input_device_connected signal", "debug")
	if not _steam_api.is_connected("input_device_disconnected", Callable(self, "_on_steam_input_device_disconnected")):
		_steam_api.connect("input_device_disconnected", Callable(self, "_on_steam_input_device_disconnected"))
		_log("Connected input_device_disconnected signal", "debug")

	_refresh_controllers()
	_log("Controllers after refresh=%s" % [_describe(_controllers)], "debug")

	if _controllers.is_empty():
		# Defer full init until a controller connects
		_log("No controllers detected; deferring handle cache", "warning")
		if DEBUG_STEAM_INPUT:
			print("Steam Input: waiting for controller connection before caching handles")
		return

	_cache_action_sets()
	_cache_action_handles()

	var gameplay_handle: int = _resolve_action_set_handle(ACTION_SET_GAMEPLAY)
	if gameplay_handle == 0:
		push_warning("Steam Input gameplay action set handle not resolved; using native input.")
		_log("Gameplay action set handle unresolved", "error")
		if DEBUG_STEAM_INPUT:
			print("Steam Input: invalid gameplay handle=", gameplay_handle)
		return
	_got_handles = true
	_initialized = true
	set_action_set(ACTION_SET_GAMEPLAY)
	_apply_action_set_if_needed()
	_log("Steam Input initialized with controllers=%s gameplay_handle=%d" % [_describe(_controllers), gameplay_handle], "info")
	if DEBUG_STEAM_INPUT:
		print("Steam Input initialized. Controllers=", _controllers)

func _run_steam_frame() -> void:
	if _steam_api and "runFrame" in _steam_api:
		_steam_api.runFrame()

func _refresh_controllers() -> void:
	if _steam_api == null or not "getConnectedControllers" in _steam_api:
		_controllers = []
		_primary_controller = 0
		_log("Steam API missing getConnectedControllers; clearing controllers", "warning")
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
	if controllers_changed:
		_log("Controllers changed primary=%d controllers=%s" % [_primary_controller, _describe(_controllers)], "info")

func _apply_action_set_if_needed() -> void:
	if not _pending_action_set_change:
		return
	_pending_action_set_change = false
	# Always resolve to gameplay; fall back if needed.
	var handle: int = _resolve_action_set_handle(ACTION_SET_GAMEPLAY)
	if handle == 0 or _steam_api == null or not "activateActionSet" in _steam_api:
		_log("Unable to activate action set; handle=%d has_api=%s" % [handle, _describe(_steam_api != null)], "warning")
		return
	for controller in _controllers:
		_steam_api.activateActionSet(controller, handle)
	_log("Activated action set %s handle=%d on controllers=%s" % [str(ACTION_SET_GAMEPLAY), handle, _describe(_controllers)], "debug")
	if DEBUG_STEAM_INPUT:
		print("Steam Input: activated set ", str(ACTION_SET_GAMEPLAY), " handle=", handle)

func _poll_inputs() -> void:
	var new_states: Dictionary = {}
	var previous_states: Dictionary = _current_digital_states if _current_digital_states is Dictionary else {}
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
	var states_changed: bool = previous_states != new_states
	_previous_digital_states = previous_states.duplicate(true)
	_current_digital_states = new_states
	if states_changed:
		var active_actions: Array[String] = []
		for action_name in new_states.keys():
			var state_map_variant: Variant = new_states[action_name]
			if state_map_variant is Dictionary:
				var state_map: Dictionary = state_map_variant
				for pressed_variant in state_map.values():
					if bool(pressed_variant):
						active_actions.append(String(action_name))
						break
			if active_actions.is_empty():
				_log("Digital state changed with no active actions; controllers=%s" % [_describe(_controllers)], "debug")
			else:
				_log("Digital actions active=%s primary=%d" % [_describe(active_actions), _primary_controller], "debug")
	_update_axis_state()

func _update_axis_state() -> void:
	var previous_axis: Vector2 = _current_axis
	_current_axis = Vector2.ZERO
	if _primary_controller == 0 or _analog_handle == 0 or _steam_api == null:
		return
	if not "getAnalogActionData" in _steam_api:
		if not _logged_missing_analog_api:
			_logged_missing_analog_api = true
			_log("Steam API missing getAnalogActionData; primary=%d handle=%d" % [_primary_controller, _analog_handle], "warning")
		return
	var data: Variant = _steam_api.call("getAnalogActionData", _primary_controller, _analog_handle)
	if typeof(data) != TYPE_DICTIONARY:
		if not _logged_invalid_analog_data:
			_logged_invalid_analog_data = true
			_log("Analog action data not dictionary; primary=%d handle=%d type=%d" % [_primary_controller, _analog_handle, typeof(data)], "error")
		return
	var active: bool = bool(data.get("active", data.get("bActive", false)))
	if not active:
		return
	var x: float = float(data.get("x", 0.0))
	var y: float = float(data.get("y", 0.0))
	var new_axis: Vector2 = Vector2(x, y)
	if new_axis.length_squared() > 0.0:
		_current_axis = new_axis
		if not new_axis.is_equal_approx(previous_axis):
			_log("Analog axis updated axis=%s" % [_describe(_current_axis)], "debug")
	elif previous_axis.length_squared() > 0.0:
		_log("Analog axis returned to zero", "debug")

func _cache_action_sets() -> void:
	_action_set_handles.clear()
	if _steam_api == null or not "getActionSetHandle" in _steam_api:
		_log("Cannot cache action sets; API missing getActionSetHandle", "warning")
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
	_log("Cached action sets gameplay=%d menu=%d" % [gameplay_handle, menu_handle], "debug")

func _cache_action_handles() -> void:
	_digital_handles.clear()
	_analog_handle = 0
	if _steam_api == null:
		_log("Cannot cache action handles; Steam API is null", "warning")
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
			else:
				_log("Digital handle missing for action=%s" % [action_name], "warning")
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
				_log("Using fallback analog handle for move action handle=%d" % [analog_handle_fallback], "debug")
	
	_reset_digital_state_cache()
	_got_handles = true
	if DEBUG_STEAM_INPUT:
		print("Steam Input: cached digital actions=", _digital_handles.keys(), " analog_move=", _analog_handle)
	_log("Cached digital handles for actions=%s analog_move=%d" % [_describe(_digital_handles.keys()), _analog_handle], "debug")

func _reset_digital_state_cache() -> void:
	_current_digital_states.clear()
	_previous_digital_states.clear()
	for action in _digital_handles.keys():
		_current_digital_states[action] = {}
		_previous_digital_states[action] = {}
	_log("Reset digital state cache for actions=%s" % [_describe(_digital_handles.keys())], "debug")

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
				_log("Action pressed action=%s controller=%d" % [String(action), controller], "info")
				return true
			if not rising and not current and previous:
				_log("Action released action=%s controller=%d" % [String(action), controller], "info")
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
		if not _logged_missing_digital_api:
			_logged_missing_digital_api = true
			_log("Steam API missing getDigitalActionData; controller=%d handle=%d" % [controller, handle], "warning")
		return false
	var data: Variant = _steam_api.call("getDigitalActionData", controller, handle)
	if typeof(data) != TYPE_DICTIONARY:
		if not _logged_invalid_digital_data:
			_logged_invalid_digital_data = true
			_log("Digital action data not dictionary; controller=%d handle=%d type=%d" % [controller, handle, typeof(data)], "error")
		return false
	var active: bool = bool(data.get("active", data.get("bActive", false)))
	if not active:
		return false
	return bool(data.get("state", data.get("bState", false)))

func _collect_glyphs(action: StringName) -> Array[String]:
	var glyphs: Array[String] = []
	if not _initialized or _steam_api == null:
		_log("Skipping glyph collection; initialized=%s steam_api=%s" % [_describe(_initialized), _describe(_steam_api != null)], "debug")
		return glyphs
	var origins: Array = []
	var action_set_handle = _resolve_action_set_handle(_current_action_set)
	if action_set_handle == 0:
		action_set_handle = _resolve_action_set_handle(ACTION_SET_GAMEPLAY)
	if _primary_controller == 0 or action_set_handle == 0:
		_log("No glyphs: primary=%d action_set_handle=%d" % [_primary_controller, action_set_handle], "debug")
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
	if glyphs.is_empty():
		_log("No glyphs resolved for action=%s origins=%s" % [String(action), _describe(origins)], "debug")
	else:
		_log("Resolved glyphs for action=%s glyphs=%s" % [String(action), _describe(glyphs)], "debug")
	return glyphs

func _glyph_for_origin(origin: int) -> String:
	if _steam_api == null:
		_log("Steam API null while resolving glyph origin=%d" % [origin], "warning")
		return ""
	if "getGlyphForActionOrigin" in _steam_api:
		return String(_steam_api.getGlyphForActionOrigin(origin))
	if "getGlyphPNGForActionOrigin" in _steam_api:
		return String(_steam_api.getGlyphPNGForActionOrigin(origin, 0, 0))
	_log("No glyph method available for origin=%d" % [origin], "warning")
	return ""

func _resolve_action_set_handle(name: StringName) -> int:
	var lookup_name = name
	if lookup_name == DEFAULT_ACTION_SET:
		lookup_name = ACTION_SET_GAMEPLAY
	if _action_set_handles.has(lookup_name):
		return int(_action_set_handles[lookup_name])
	_log("Action set handle missing for %s" % [_describe(lookup_name)], "warning")
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
		_log("steam_ready signal received but already initialized=%s has_singleton=%s" % [_describe(_initialized), _describe(Engine.has_singleton("Steam"))], "debug")
		return
	_log("steam_ready signal received; initializing now", "info")
	_initialize()

func _on_steam_input_device_connected(input_handle: int) -> void:
	if DEBUG_STEAM_INPUT:
		print("Steam Input: device connected ", input_handle)
	_log("Controller connected handle=%d" % [input_handle], "info")
	_refresh_controllers()
	if not _got_handles:
		_cache_action_sets()
		_cache_action_handles()
		var gameplay_handle: int = _resolve_action_set_handle(ACTION_SET_GAMEPLAY)
		var menu_handle: int = _resolve_action_set_handle(ACTION_SET_MENU)
		# Initialize once gameplay is available; menu is optional for our bindings.
		if gameplay_handle != 0:
			_got_handles = true
			_initialized = true
			_log("Controller connection completed initialization gameplay_handle=%d menu_handle=%d (menu optional)" % [gameplay_handle, menu_handle], "info")
		else:
			_log("Gameplay handle unresolved on device connect; cannot initialize yet", "warning")
	_apply_action_set_if_needed()

func _on_steam_input_device_disconnected(input_handle: int) -> void:
	if DEBUG_STEAM_INPUT:
		print("Steam Input: device disconnected ", input_handle)
	_log("Controller disconnected handle=%d" % [input_handle], "warning")
	_refresh_controllers()
	if _controllers.is_empty():
		_primary_controller = 0
		_initialized = false
		_got_handles = false
		_log("All controllers removed; resetting Steam Input state", "warning")
