extends RefCounted
class_name InputBackend

const BindingModelScript: Script = preload("res://Scripts/Globals/BindingModel.gd")

static func build_binding_model(action: StringName, event: InputEvent, id: String, device: StringName, display_name: String) -> BindingModel:
	var safe_event = event.duplicate(true) if event else null
	return BindingModelScript.new(action, safe_event, id, device, display_name)

func get_actions() -> Array[StringName]:
	return []

func is_down(_action: StringName) -> bool:
	return false

func was_pressed(_action: StringName) -> bool:
	return false

func was_released(_action: StringName) -> bool:
	return false

func axis(_name: StringName = &"move") -> Vector2:
	return Vector2.ZERO

func update(_delta: float) -> void:
	pass

func set_action_set(_name: StringName) -> void:
	pass

func get_glyph_paths_for(_action: StringName) -> Array[String]:
	return []

func get_bindings(_action: StringName) -> Array[BindingModel]:
	return []

func add_binding(_action: StringName, _event: InputEvent) -> bool:
	return false

func remove_binding(_action: StringName, _binding_id: String) -> bool:
	return false

func reset_keyboard_defaults() -> void:
	pass

func open_controller_binding_panel() -> bool:
	return false

func is_steam_active() -> bool:
	return false
