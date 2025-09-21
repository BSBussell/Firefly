extends InputBackend
class_name NativeInputBackend

const AXIS_DEADZONE := 0.15

var _actions: Array[StringName] = []
var _action_lookup: Dictionary = {}
var _default_keyboard_events: Dictionary = {}

func _init() -> void:
	_refresh_actions()
	_cache_default_keyboard_events()

func get_actions() -> Array[StringName]:
	return _actions.duplicate()

func is_down(action: StringName) -> bool:
	if not InputMap.has_action(action):
		return false
	return Input.is_action_pressed(action)

func was_pressed(action: StringName) -> bool:
	if not InputMap.has_action(action):
		return false
	return Input.is_action_just_pressed(action)

func was_released(action: StringName) -> bool:
	if not InputMap.has_action(action):
		return false
	return Input.is_action_just_released(action)

func axis(name: StringName = &"move") -> Vector2:
	if name != &"move":
		return Vector2.ZERO

	var vector := _sample_prefixed_axis(name)
	if vector.length_squared() == 0.0:
		vector = _sample_common_axis()

	return _apply_deadzone(vector)

func set_action_set(_name: StringName) -> void:
	pass

func get_glyph_paths_for(_action: StringName) -> Array[String]:
	return []

func get_bindings(action: StringName) -> Array[BindingModel]:
	var bindings: Array[BindingModel] = []
	if not InputMap.has_action(action):
		return bindings

	for event in InputMap.action_get_events(action):
		var binding_id := _build_binding_id(action, event)
		var device_label := _event_device_label(event)
		var display_label := event.as_text()
		bindings.append(InputBackend.build_binding_model(action, event, binding_id, device_label, display_label))

	return bindings

func add_binding(action: StringName, event: InputEvent) -> bool:
	if not InputMap.has_action(action) or event == null:
		return false

	if _has_equivalent_event(action, event):
		return false

	InputMap.action_add_event(action, event)
	return true

func remove_binding(action: StringName, binding_id: String) -> bool:
	if not InputMap.has_action(action):
		return false

	var events := InputMap.action_get_events(action)
	for existing_event in events:
		if _build_binding_id(action, existing_event) == binding_id:
			InputMap.action_erase_event(action, existing_event)
			return true

	return false

func reset_keyboard_defaults() -> void:
	for action in _actions:
		if not InputMap.has_action(action):
			continue

		var events := InputMap.action_get_events(action)
		for index in range(events.size() - 1, -1, -1):
			var event: InputEvent = events[index]
			if event is InputEventKey:
				InputMap.action_erase_event(action, event)

		if _default_keyboard_events.has(action):
			for default_event in _default_keyboard_events[action]:
				InputMap.action_add_event(action, default_event.duplicate(true))

func open_controller_binding_panel() -> bool:
	return false

func is_steam_active() -> bool:
	return false

func _refresh_actions() -> void:
	_actions.clear()
	_action_lookup.clear()
	for raw_name in InputMap.get_actions():
		var action_name := StringName(raw_name)
		_actions.append(action_name)
		_action_lookup[action_name] = true

func _cache_default_keyboard_events() -> void:
	_default_keyboard_events.clear()
	for action in _actions:
		if not InputMap.has_action(action):
			continue

		var defaults: Array[InputEvent] = []
		for event in InputMap.action_get_events(action):
			if event is InputEventKey:
				defaults.append(event.duplicate(true))

		if defaults.size() > 0:
			_default_keyboard_events[action] = defaults

func _sample_prefixed_axis(name: StringName) -> Vector2:
	var base := String(name)
	var left := StringName(base + "_left")
	var right := StringName(base + "_right")
	var up := StringName(base + "_up")
	var down := StringName(base + "_down")

	if _has_all_actions([left, right, up, down]):
		return Input.get_vector(left, right, up, down, 0.0)

	return Vector2.ZERO

func _sample_common_axis() -> Vector2:
	var left := _first_valid([StringName("Left"), StringName("move_left"), StringName("ui_left")])
	var right := _first_valid([StringName("Right"), StringName("move_right"), StringName("ui_right")])
	var up := _first_valid([StringName("Up"), StringName("move_up"), StringName("ui_up")])
	var down := _first_valid([StringName("Down"), StringName("move_down"), StringName("ui_down")])

	var vector := Vector2.ZERO
	vector.x = _read_axis_component(left, right)
	vector.y = _read_axis_component(up, down)

	return vector

func _apply_deadzone(vector: Vector2) -> Vector2:
	return Vector2.ZERO if vector.length_squared() < AXIS_DEADZONE * AXIS_DEADZONE else vector

func _has_all_actions(actions: Array[StringName]) -> bool:
	for action in actions:
		if not _is_valid_action(action):
			return false
	return true

func _first_valid(candidates: Array[StringName]) -> StringName:
	for candidate in candidates:
		if _is_valid_action(candidate):
			return candidate
	return StringName()

func _is_valid_action(action: StringName) -> bool:
	return action != StringName() and _action_lookup.has(action)

func _read_axis_component(negative_action: StringName, positive_action: StringName) -> float:
	var value := 0.0
	if _is_valid_action(positive_action):
		value += Input.get_action_strength(positive_action)
	if _is_valid_action(negative_action):
		value -= Input.get_action_strength(negative_action)
	return clamp(value, -1.0, 1.0)

func _build_binding_id(action: StringName, event: InputEvent) -> String:
	return "%s::%s" % [String(action), _serialize_event(event)]

func _serialize_event(event: InputEvent) -> String:
	if event is InputEventKey:
		var key_event := event as InputEventKey
		return "key:%d:%d:%d:%d:%d:%d:%d:%d" % [key_event.keycode, key_event.physical_keycode, key_event.unicode, key_event.alt_pressed, key_event.ctrl_pressed, key_event.shift_pressed, key_event.meta_pressed, key_event.device]
	elif event is InputEventJoypadButton:
		var joy_button := event as InputEventJoypadButton
		return "joy_button:%d:%d" % [joy_button.device, joy_button.button_index]
	elif event is InputEventJoypadMotion:
		var joy_motion := event as InputEventJoypadMotion
		var direction :=  1 if joy_motion.axis_value >= 0.0 else -1
		return "joy_motion:%d:%d:%d" % [joy_motion.device, joy_motion.axis, direction]
	elif event is InputEventMouseButton:
		var mouse_button := event as InputEventMouseButton
		return "mouse_button:%d:%d" % [mouse_button.device, mouse_button.button_index]
	return event.as_text()

func _event_device_label(event: InputEvent) -> StringName:
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		return StringName("gamepad")
	elif event is InputEventKey:
		return StringName("keyboard")
	elif event is InputEventMouseButton:
		return StringName("mouse")
	return StringName("unknown")

func _has_equivalent_event(action: StringName, event: InputEvent) -> bool:
	var target_signature := _serialize_event(event)
	for existing_event in InputMap.action_get_events(action):
		if _serialize_event(existing_event) == target_signature:
			return true
	return false
