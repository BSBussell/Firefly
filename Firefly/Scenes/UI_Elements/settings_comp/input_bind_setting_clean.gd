extends BaseSetting
#class_name InputBindSetting

@onready var label: Label = $SettingName
@onready var bindings_container: HBoxContainer = $BindingsContainer
@onready var add_binding_button: Button = $AddBindingButton
@onready var focus = $Focus
@onready var press = $Press

var binding_button_scene = preload("res://Scenes/UI_Elements/settings_comp/input_binding_button.tscn")

# Input icon paths
const KEYBOARD_ICONS_PATH = "res://Assets/Graphics/UI/inputs/prototypegames_16x16_input_prompts/tiles/keyboard_inputs/outlined/"
const CONTROLLER_ICONS_PATH = "res://Assets/Graphics/UI/inputs/prototypegames_16x16_input_prompts/tiles/controller_inputs/outlined/"
const CONTROLLER_DIRECTIONAL_PATH = "res://Assets/Graphics/UI/inputs/prototypegames_16x16_input_prompts/tiles/controller_inputs/"
const KENNY_TILES_PATH = "res://Assets/Graphics/UI/inputs/KennyTiles/"

# Key mappings for icons
const KEY_ICON_MAP = {
	KEY_SPACE: "space.png",
	KEY_ENTER: "enter.png",
	KEY_ESCAPE: "esc.png",
	KEY_TAB: "tab_left.png",
	KEY_DELETE: "del.png",
	KEY_CTRL: "ctrl.png",
	KEY_SHIFT: "shift.png",
	KEY_ALT: "alt.png",
	KEY_UP: "up.png",
	KEY_DOWN: "down.png",
	KEY_LEFT: "left.png",
	KEY_RIGHT: "right.png",
	KEY_F1: "f1.png",
	KEY_F2: "f2.png",
	KEY_F3: "f3.png",
	KEY_F4: "f4.png",
	KEY_F5: "f5.png",
	KEY_F6: "f6.png",
	KEY_F7: "f7.png",
	KEY_F8: "f8.png",
	KEY_F9: "f9.png",
	KEY_F10: "f10.png",
	KEY_F11: "f11.png",
	KEY_F12: "f12.png"
}

# Controller button mappings (for Xbox controller)
const JOY_ICON_MAP = {
	JOY_BUTTON_A: "a.png",
	JOY_BUTTON_B: "b.png",
	JOY_BUTTON_X: "x.png",
	JOY_BUTTON_Y: "y.png",
	JOY_BUTTON_LEFT_SHOULDER: "l1.png",
	JOY_BUTTON_RIGHT_SHOULDER: "r1.png",
	JOY_BUTTON_BACK: "back.png",
	JOY_BUTTON_START: "triangle.png",
	JOY_BUTTON_LEFT_STICK: "L_Stick_Click.png",
	JOY_BUTTON_RIGHT_STICK: "R_Stick_Click.png",
	JOY_BUTTON_DPAD_UP: "xb_up.png",
	JOY_BUTTON_DPAD_DOWN: "xb_down.png",
	JOY_BUTTON_DPAD_LEFT: "xb_left.png",
	JOY_BUTTON_DPAD_RIGHT: "xb_right.png"
}

var action_name: String = ""
var current_bindings: Array[InputEvent] = []
var binding_buttons: Array[Node] = []
var awaiting_input: bool = false
var current_editing_button: Button = null

## The dictionary of information for this setting (from BaseSetting)
var setting_json = {}

signal binding_changed(action: String, events: Array[InputEvent])

## Pass the JSON to the component (called by settings system)
func pass_json(json):
	setting_json = json

## At this point we assume you have setting_json to work with (called by settings system)
func setup_element():
	# Configure from setting_json data
	if setting_json.has("action_name"):
		action_name = setting_json.get("action_name", "")
		label.text = setting_json.get("label", "Input Binding")
	
	# Only proceed if we have a valid action name
	if not action_name.is_empty():
		# Load current bindings from InputMap
		load_current_bindings()
		
		# Set up UI
		refresh_binding_ui()
		
		# Configure the add button with Plus.png icon
		add_binding_button.text = ""
		add_binding_button.icon = load("res://Assets/Graphics/UI/inputs/KennyTiles/Plus.png")
		
		# Connect add button
		if not add_binding_button.pressed.is_connected(_on_add_binding_pressed):
			add_binding_button.pressed.connect(_on_add_binding_pressed)

func load_current_bindings():
	current_bindings.clear()
	var events = InputMap.action_get_events(action_name)
	for event in events:
		if event is InputEventKey or event is InputEventJoypadButton or event is InputEventJoypadMotion:
			current_bindings.append(event)

func refresh_binding_ui():
	# Clear existing binding buttons
	for button_container in binding_buttons:
		if button_container and is_instance_valid(button_container):
			button_container.queue_free()
	binding_buttons.clear()
	
	# Create new binding buttons
	for i in range(current_bindings.size()):
		var event = current_bindings[i]
		create_binding_button(event, i)
	
	# Update focus navigation
	update_focus_navigation()

func create_binding_button(event: InputEvent, index: int):
	var button_container = binding_button_scene.instantiate()
	bindings_container.add_child(button_container)
	binding_buttons.append(button_container)
	
	var binding_button: Button = button_container.get_node("BindingButton")
	var clear_button: Button = button_container.get_node("ClearButton")
	
	# Set up binding button with icons
	binding_button.text = ""
	
	# Add multiple icons for this input
	var icons_to_add = get_input_icons(event)
	
	# Clear any existing icons first
	for child in binding_button.get_children():
		if child is TextureRect:
			child.queue_free()
	
	# Add icon textures as children
	for icon_path in icons_to_add:
		var texture_rect = TextureRect.new()
		var texture = load(icon_path)
		if texture:
			texture_rect.texture = texture
			texture_rect.custom_minimum_size = Vector2(120, 120)
			texture_rect.size = Vector2(120, 120)
			texture_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			binding_button.add_child(texture_rect)
	
	# Connect signals
	binding_button.pressed.connect(func(): start_input_capture(binding_button, index))
	clear_button.pressed.connect(func(): remove_binding(index))
	
	# Audio feedback
	binding_button.focus_entered.connect(func(): focus.play())
	binding_button.pressed.connect(func(): press.play())
	clear_button.focus_entered.connect(func(): focus.play())
	clear_button.pressed.connect(func(): press.play())

func get_input_icons(event: InputEvent) -> Array[String]:
	var icons: Array[String] = []
	
	if event is InputEventKey:
		var key_event = event as InputEventKey
		
		# Add modifier icons first
		if key_event.ctrl_pressed:
			icons.append(KEYBOARD_ICONS_PATH + "ctrl.png")
		if key_event.shift_pressed:
			icons.append(KEYBOARD_ICONS_PATH + "shift.png")
		if key_event.alt_pressed:
			icons.append(KEYBOARD_ICONS_PATH + "alt.png")
		if key_event.meta_pressed:
			icons.append(KEYBOARD_ICONS_PATH + "unlock.png")
		
		# Add main key icon
		var key_icon = get_key_icon(key_event)
		if not key_icon.is_empty():
			icons.append(key_icon)
			
	elif event is InputEventJoypadButton:
		var joy_event = event as InputEventJoypadButton
		var button_icon = get_controller_button_icon(joy_event.button_index)
		if not button_icon.is_empty():
			icons.append(button_icon)
			
	elif event is InputEventJoypadMotion:
		var motion_event = event as InputEventJoypadMotion
		var axis_icon = get_controller_axis_icon(motion_event.axis, motion_event.axis_value)
		if not axis_icon.is_empty():
			icons.append(axis_icon)
	
	return icons

func get_key_icon(key_event: InputEventKey) -> String:
	var keycode = key_event.physical_keycode if key_event.physical_keycode != 0 else key_event.keycode
	
	# Check special keys first
	if KEY_ICON_MAP.has(keycode):
		return KEYBOARD_ICONS_PATH + KEY_ICON_MAP[keycode]
	
	# Handle letter keys (A-Z)
	if keycode >= KEY_A and keycode <= KEY_Z:
		var letter = char(keycode).to_lower()
		return KEYBOARD_ICONS_PATH + "small_letters/" + letter + ".png"
	
	# Handle number keys (0-9)
	if keycode >= KEY_0 and keycode <= KEY_9:
		var number = str(keycode - KEY_0)
		return KEYBOARD_ICONS_PATH + "small_letters/" + number + ".png"
	
	# Default fallback
	return KEYBOARD_ICONS_PATH + "question.png"

func get_controller_button_icon(button_index: int) -> String:
	if JOY_ICON_MAP.has(button_index):
		var filename = JOY_ICON_MAP[button_index]
		# Try Kenny tiles first for better looking icons
		if filename in ["L_Stick_Click.png", "R_Stick_Click.png", "back.png"]:
			return KENNY_TILES_PATH + filename
		else:
			return CONTROLLER_ICONS_PATH + filename
	
	return CONTROLLER_ICONS_PATH + "question.png"

func get_controller_axis_icon(axis: int, axis_value: float) -> String:
	# Handle stick movement icons
	match axis:
		JOY_AXIS_LEFT_X:
			if axis_value > 0:
				return KENNY_TILES_PATH + "L_Stick_Right.png"
			else:
				return KENNY_TILES_PATH + "L_Stick_Left.png"
		JOY_AXIS_LEFT_Y:
			if axis_value > 0:
				return KENNY_TILES_PATH + "L_Stick_Down.png"
			else:
				return KENNY_TILES_PATH + "L_Stick_Up.png"
		JOY_AXIS_RIGHT_X:
			if axis_value > 0:
				return KENNY_TILES_PATH + "R_Stick_Right.png"
			else:
				return KENNY_TILES_PATH + "R_Stick_Left.png"
		JOY_AXIS_RIGHT_Y:
			if axis_value > 0:
				return KENNY_TILES_PATH + "R_Stick_Down.png"
			else:
				return KENNY_TILES_PATH + "R_Stick_Up.png"
		JOY_AXIS_TRIGGER_LEFT:
			return CONTROLLER_ICONS_PATH + "l2.png"
		JOY_AXIS_TRIGGER_RIGHT:
			return CONTROLLER_ICONS_PATH + "r2.png"
	
	return CONTROLLER_ICONS_PATH + "question.png"

# BaseSetting focus management methods
func set_above_focus(focus_obj):
	# Set focus chain for navigation
	if add_binding_button:
		add_binding_button.focus_neighbor_top = focus_obj.get_path()

func set_below_focus(focus_obj):
	# Set focus chain for navigation
	if add_binding_button:
		add_binding_button.focus_neighbor_bottom = focus_obj.get_path()

func set_left_focus(focus_obj):
	# Set focus chain for navigation
	if add_binding_button:
		add_binding_button.focus_neighbor_left = focus_obj.get_path()

func set_right_focus(focus_obj):
	# Set focus chain for navigation
	if add_binding_button:
		add_binding_button.focus_neighbor_right = focus_obj.get_path()

func get_focus_obj():
	# Return the main focusable element
	return add_binding_button

func _on_add_binding_pressed():
	start_input_capture(null, -1)

func remove_binding(index: int):
	if index >= 0 and index < current_bindings.size():
		# Remove from InputMap
		InputMap.action_erase_event(action_name, current_bindings[index])
		
		# Remove from our array
		current_bindings.remove_at(index)
		
	# Refresh UI
	refresh_binding_ui()
	
	# Save input bindings to config
	_config.save_input_bindings()
	
	# Emit signal for external listeners
	binding_changed.emit(action_name, current_bindings)
	
	# Play sound effect
	press.play()

func start_input_capture(button: Button, _index: int):
	awaiting_input = true
	current_editing_button = button
	
	# Change button appearance to show we're waiting for input
	if button:
		button.modulate = Color.YELLOW
		button.text = "..."
	else:
		add_binding_button.text = "..."
		add_binding_button.icon = null
		add_binding_button.modulate = Color.YELLOW
	
	# Make sure we can receive input events
	set_process_input(true)
	
	# Also ensure this node can receive input
	set_process_mode(Node.PROCESS_MODE_ALWAYS)
	
	# Release focus to ensure input isn't consumed by focused element
	if button:
		button.release_focus()
	else:
		add_binding_button.release_focus()
	
	print("Started input capture for action: ", action_name)

func _input(event: InputEvent):
	if not awaiting_input:
		return
	
	print("Input captured: ", event.get_class(), " - ", event)
	
	# Consume the event immediately to prevent it from being processed elsewhere
	get_viewport().set_input_as_handled()
	
	# Only capture key presses, joypad buttons, and joypad motion
	if not (event is InputEventKey or event is InputEventJoypadButton or event is InputEventJoypadMotion):
		print("Ignoring input type: ", event.get_class())
		return
		
	# Ignore key release events
	if event is InputEventKey and not event.pressed:
		print("Ignoring key release")
		return
		
	# Ignore escape key - use it to cancel input capture
	if event is InputEventKey and event.keycode == KEY_ESCAPE:
		print("Escape pressed - canceling input capture")
		cancel_input_capture()
		return
	
	# For joypad motion, only capture significant movements
	if event is InputEventJoypadMotion:
		var joy_motion = event as InputEventJoypadMotion
		if abs(joy_motion.axis_value) < 0.5:
			print("Ignoring small joypad motion: ", joy_motion.axis_value)
			return
		# Normalize the axis value to 1.0 or -1.0
		joy_motion.axis_value = 1.0 if joy_motion.axis_value > 0 else -1.0
	
	# Check if this binding already exists for this action
	var existing_events = InputMap.action_get_events(action_name)
	for existing_event in existing_events:
		if events_are_equivalent(event, existing_event):
			print("Input binding already exists for action: ", action_name)
			cancel_input_capture()
			return
	
	print("Applying new binding: ", event)
	apply_new_binding(event)

func events_are_equivalent(event1: InputEvent, event2: InputEvent) -> bool:
	if event1.get_class() != event2.get_class():
		return false
		
	if event1 is InputEventKey and event2 is InputEventKey:
		var key1 = event1 as InputEventKey
		var key2 = event2 as InputEventKey
		return (key1.physical_keycode == key2.physical_keycode and
				key1.keycode == key2.keycode and
				key1.ctrl_pressed == key2.ctrl_pressed and
				key1.shift_pressed == key2.shift_pressed and
				key1.alt_pressed == key2.alt_pressed and
				key1.meta_pressed == key2.meta_pressed)
				
	elif event1 is InputEventJoypadButton and event2 is InputEventJoypadButton:
		var joy1 = event1 as InputEventJoypadButton
		var joy2 = event2 as InputEventJoypadButton
		return (joy1.button_index == joy2.button_index and
				joy1.device == joy2.device)
				
	elif event1 is InputEventJoypadMotion and event2 is InputEventJoypadMotion:
		var motion1 = event1 as InputEventJoypadMotion
		var motion2 = event2 as InputEventJoypadMotion
		return (motion1.axis == motion2.axis and
				motion1.device == motion2.device and
				sign(motion1.axis_value) == sign(motion2.axis_value))
	
	return false

func apply_new_binding(event: InputEvent):
	if current_editing_button and current_editing_button != add_binding_button:
		# Replacing an existing binding - find the correct index
		var index = -1
		for i in range(binding_buttons.size()):
			var container = binding_buttons[i]
			if container and is_instance_valid(container):
				var binding_button = container.get_node("BindingButton")
				if binding_button == current_editing_button:
					index = i
					break
		
		if index >= 0 and index < current_bindings.size():
			# Remove old binding from InputMap
			InputMap.action_erase_event(action_name, current_bindings[index])
			
			# Add new binding to InputMap
			InputMap.action_add_event(action_name, event)
			
			# Update our array
			current_bindings[index] = event
	else:
		# Adding a new binding
		InputMap.action_add_event(action_name, event)
		current_bindings.append(event)
	
	# Stop input capture
	stop_input_capture()
	
	# Refresh UI
	refresh_binding_ui()
	
	# Save input bindings to config
	_config.save_input_bindings()
	
	# Emit signal
	binding_changed.emit(action_name, current_bindings)
	
	# Play sound effect
	press.play()

func cancel_input_capture():
	stop_input_capture()
	
	# Reset button appearance
	if current_editing_button:
		if current_editing_button == add_binding_button:
			add_binding_button.text = ""
			var plus_icon = load("res://Assets/Graphics/UI/inputs/KennyTiles/Plus.png")
			add_binding_button.icon = plus_icon
		# For other buttons, they'll be refreshed by refresh_binding_ui
		refresh_binding_ui()

func stop_input_capture():
	awaiting_input = false
	current_editing_button = null
	set_process_input(false)
	
	# Reset add button to show Plus icon
	if add_binding_button:
		add_binding_button.modulate = Color.WHITE
		add_binding_button.text = ""
		var plus_icon = load("res://Assets/Graphics/UI/inputs/KennyTiles/Plus.png")
		add_binding_button.icon = plus_icon
	
	print("Stopped input capture for action: ", action_name)

func update_focus_navigation():
	# Update focus navigation for all binding buttons
	var focusable_controls: Array[Control] = []
	
	# Add binding buttons
	for button_container in binding_buttons:
		if button_container and is_instance_valid(button_container):
			var binding_button = button_container.get_node("BindingButton")
			var clear_button = button_container.get_node("ClearButton")
			focusable_controls.append(binding_button)
			focusable_controls.append(clear_button)
	
	# Add the add binding button
	focusable_controls.append(add_binding_button)
	
	# Set up focus chain
	for i in range(focusable_controls.size()):
		var current_control = focusable_controls[i]
		var next_control = focusable_controls[(i + 1) % focusable_controls.size()]
		var prev_control = focusable_controls[(i - 1 + focusable_controls.size()) % focusable_controls.size()]
		
		current_control.focus_next = next_control.get_path()
		current_control.focus_previous = prev_control.get_path()

# BaseSetting interface methods
func get_focus_control() -> Control:
	if binding_buttons.size() > 0:
		var first_container = binding_buttons[0]
		if first_container and is_instance_valid(first_container):
			return first_container.get_node("BindingButton")
	return add_binding_button

func save_data() -> Dictionary:
	return {"action_name": action_name}

func load_data(data: Dictionary) -> void:
	if data.has("action_name"):
		action_name = data["action_name"]
		load_current_bindings()
		refresh_binding_ui()
