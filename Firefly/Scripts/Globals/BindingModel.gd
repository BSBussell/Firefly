extends RefCounted
class_name BindingModel

var id: String
var action: StringName
var event: InputEvent
var device: StringName
var display_name: String

func _init(action: StringName, event: InputEvent, id: String, device: StringName, display_name: String) -> void:
	self.action = action
	self.event = event
	self.id = id
	self.device = device
	self.display_name = display_name

func duplicate_event() -> InputEvent:
	return event.duplicate(true) if event else null
