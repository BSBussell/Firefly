extends State

# Camera movement parameters
## The color of the camera target when we are in this
@export var Cursor_Color: Color

## The maximum speed the camera will move
@export var Maximum_Speed: Vector2 = Vector2(20, 20)
@export var Minimum_Speed: Vector2 = Vector2(5, 5)

## The default acceleration
@export var BaseAcceleration: Vector2 = Vector2(0.6, 0.6)

@export_category("Follow/Blend")
## Exponential base used to derive per-axis blend from follow speed
@export var Blend_Exp_Base: float = 0.5
## Round the final camera position to whole pixels
@export var Round_Final_Position: bool = true

@export_category("Lookahead")
## Enable/disable horizontal lookahead offset
@export var Use_Lookahead: bool = false
## If player's abs X velocity >= this, start applying lookahead
@export var Lookahead_Speed_Threshold: float = 152.0
## Multiplier to determine max speed reference (threshold * multiplier)
@export var Lookahead_Max_Speed_Multiplier: float = 1.5
## Maximum horizontal offset applied by lookahead (pixels)
@export var Lookahead_Max_Offset_X: float = 30.0
## Blend rate when approaching the lookahead offset
@export var Lookahead_Arrive_Blend: float = 0.025
## Blend rate when returning from lookahead back to zero
@export var Lookahead_Return_Blend: float = 0.05
## Disable lookahead when the player is dying
@export var Dying_Disables_Lookahead: bool = true

@export_category("Target Grouping")
## Speed at which multi-target blend approaches the desired blend
@export var MultiTarget_Blend_Approach: float = 0.01
## Speed at which grouping offset lerps toward its target when set changes
@export var Grouping_Offset_Approach: float = 0.01
## Reset grouping smoothing when the active target set changes
@export var Reset_Smoothing_On_Target_Change: bool = true
## Cursor color used briefly when target set changes
@export var Target_Change_Debug_Color: Color = Color("#00FFFF")
## Respect target_snap on active CameraTargets
@export var Allow_Target_Snap: bool = true
## Reset the group-blend weight to the new targets' preferred blend when the set changes
@export var Reset_Group_Blend_On_Target_Change: bool = true

@onready var cursor = $"../../Cursor"
@onready var control: PlayerCam 
@onready var player: Flyph




# The acceleratino that's actually used
var accel: Vector2 = Vector2.ZERO

var follow_speed: Vector2 = Vector2.ZERO

var current_target_offset: Vector2 = Vector2.ZERO

# Cached base values and effective values for config-driven tuning
var _base_max_speed: Vector2
var _base_min_speed: Vector2
var _base_accel: Vector2
var Effective_Maximum_Speed: Vector2
var Effective_Minimum_Speed: Vector2
var Effective_BaseAcceleration: Vector2
var _camera_speed_index: int = 3
var _camera_speed_scale: float = 1.0

func _ready():
	# Cache base values from exports
	_base_max_speed = Maximum_Speed
	_base_min_speed = Minimum_Speed
	_base_accel = BaseAcceleration
	
	# Listen for settings changes and initialize from config
	_config.connect_to_config_changed(Callable(self, "config_changed"))
	update_settings_from_config()


func enter() -> void:
	
	
	# Refresh settings and apply effective values
	update_settings_from_config()
	accel = Effective_BaseAcceleration
	follow_speed = Effective_Minimum_Speed
	
	control = parent as PlayerCam
	player = control.Player
	
	# Set this as the default base position
	#current_target_position = player.global_position - control.startingPos
	
	if cursor.visible:
		cursor.modulate = Cursor_Color

func exit() -> void:
	pass

func process_frame(delta: float) -> State:
	move_camera(delta)
	return check_state()

func process_physics(delta: float) -> State:
	move_camera(delta)
	return check_state()

func move_camera(delta):
	
	var target_position = calculate_target_position(delta)
	
	
	
	
	
	# Smoothly move the camera towards the target position
	follow_speed.x = move_toward(follow_speed.x, Effective_Maximum_Speed.x, accel.x)
	#min(Maximum_Speed.x, follow_speed.x + accel.x)
	follow_speed.y = move_toward(follow_speed.y, Effective_Maximum_Speed.y, accel.y)
	#min(Maximum_Speed.y, follow_speed.y + accel.y)
	
	# Calculate Blend
	var blend: Vector2 = Vector2.ZERO
	blend.x = 1 - pow(Blend_Exp_Base, follow_speed.x * delta)
	blend.y = 1 - pow(Blend_Exp_Base, follow_speed.y * delta)
	
	# Gerblesh
	control.actual_cam_pos.x = _gerblesh.lerpi(control.actual_cam_pos.x, target_position.x, blend.x)	
	control.actual_cam_pos.y = _gerblesh.lerpi(control.actual_cam_pos.y, target_position.y, blend.y)
	
	if Round_Final_Position:
		control.global_position = control.actual_cam_pos.round()
	else:
		control.global_position = control.actual_cam_pos
	control.camera_2d.align()


var multi_target_smoothing: float = 0.0
var smoothing_factor_2: float = 0.0
var dict_hash: int = 0
var settled: bool = true
var current_grouping_offset: Vector2 = Vector2.ZERO
var _had_snap_last_frame: bool = false

func calculate_target_position(delta: float) -> Vector2:
	
	var base_target: Vector2 = player.global_position - control.startingPos	
	var position: Vector2 = base_target
	var offset: Vector2 = Vector2.ZERO
	
	if not (Dying_Disables_Lookahead and player.dying):
		offset = calc_horiz_offset(delta)
	
	
	# Check if there are any targets to look at
	var targets_center = get_targets_center()
	
	# Check if the list of targets has changed
	var id = control.targets.hash()
	if id != dict_hash:
		dict_hash = id
		if Reset_Smoothing_On_Target_Change:
			smoothing_factor_2 = 0
		if Reset_Group_Blend_On_Target_Change:
			multi_target_smoothing = get_targets_blend()
		cursor.modulate = Target_Change_Debug_Color
	else:
		cursor.modulate = Cursor_Color
	
	
	if targets_center != Vector2.ZERO:
		
		
		
		#var targets_offset: Vector2
		var grouping_offset: Vector2
		grouping_offset = get_targets_offset(position, targets_center)
		
		smoothing_factor_2 = move_toward(smoothing_factor_2, 1.0, Grouping_Offset_Approach)
		
		# Lerp towards this new offset
		current_grouping_offset = _gerblesh.lerpiVec(current_grouping_offset, grouping_offset, smoothing_factor_2)
		#current_grouping_offset = grouping_offset
		
	
		
	
	# Otherwise if we're turning off target tracking
	else:
		
		# Reset the hash
		dict_hash = 0
		
		# Reset the smoothing
		smoothing_factor_2 = move_toward(smoothing_factor_2, 1.0, Grouping_Offset_Approach)
		
		# Lerp towards our origin
		current_grouping_offset = _gerblesh.lerpiVec(current_grouping_offset, Vector2.ZERO, smoothing_factor_2)
		
		
		
		
		
	if not (Dying_Disables_Lookahead and player.dying):
		#print("DC: Targets Offset", targets_center)
		#print("DC: Grouping Offset: ",current_grouping_offset)
		#print("DC: Position: ", position)
		# I want it to do this normally
		position += current_grouping_offset
		if Use_Lookahead:
			position += offset
		var has_snap := false
		for target in control.targets.values():
			if Allow_Target_Snap and target.target_snap:
				position = targets_center
				has_snap = true
		_had_snap_last_frame = has_snap
	
	return position

func calc_horiz_offset(_delta: float) -> Vector2:
	
	# The default offset
	var offset = Vector2.ZERO
	
	## The rate that the current offset will approach our goal offset
	var blend: Vector2 = Vector2(0.1, 0.1)
	
	# Abs the players velocity only once
	var player_speed: Vector2 = abs(player.velocity)
	
	# If moving quickly horizontally (and not when wall jumping)
	if player_speed.x >= player.speed and not player.wallJumping:

		# Establish max reference and target offset from designer knobs
		var max_horiz_speed: float = Lookahead_Speed_Threshold * Lookahead_Max_Speed_Multiplier
		var horiz_offset: float = Lookahead_Max_Offset_X * sign(player.velocity.x)

		# Normalize our blending
		var normed_blend = (player_speed.x - Lookahead_Speed_Threshold) / (max_horiz_speed - Lookahead_Speed_Threshold)
		
		
		# Using lerp to have us approach horiz offset as speed approaches max
		offset.x += lerpf(0, horiz_offset, min(1.0, normed_blend)) 
		
		
		# Slowly move the offset to this
		blend.x = Lookahead_Arrive_Blend
		
	
	
	# If we are returning to zero, ease into it
	if current_target_offset != Vector2.ZERO and offset == Vector2.ZERO:
		blend = Vector2(Lookahead_Return_Blend, Lookahead_Return_Blend)
		
	

	# Move the actual target towards our new calc'd goal
	current_target_offset.x = _gerblesh.lerpi(current_target_offset.x, offset.x, blend.x)
	current_target_offset.y = _gerblesh.lerpi(current_target_offset.y, offset.y, blend.y)
	
	return current_target_offset
	

# Get all on-screen targets and find the weighted center point between them all
func get_targets_center() -> Vector2:
	var weighted_sum = Vector2.ZERO
	var total_pull_strength = 0.0

	for target in control.targets.values():
		weighted_sum += target.global_position * target.pull_strength
		total_pull_strength += target.pull_strength

	if total_pull_strength > 0:
		return weighted_sum / total_pull_strength  # Weighted average position
	else:
		return Vector2.ZERO  # Return a default position if no targets exist


func get_targets_blend() -> float:
	
	var blend: float = 0.3
	var current_priority: int = -1
	
	for target in control.targets.values():
		if current_priority < target.blend_priority:
			current_priority = target.blend_priority
			blend = target.blend_override
			
		
	return blend




func get_targets_offset(base_target: Vector2, targets_center: Vector2) -> Vector2:
	var blend_max = get_targets_blend()
	
	# Update the smoothing factor
	multi_target_smoothing = move_toward(multi_target_smoothing, blend_max, MultiTarget_Blend_Approach)
	
	# Smoothly transition the offset towards the new center
	var current_grouping_position: Vector2 = Vector2.ZERO
	current_grouping_position.x = _gerblesh.lerpi(base_target.x, targets_center.x, multi_target_smoothing)
	current_grouping_position.y = _gerblesh.lerpi(base_target.y, targets_center.y, multi_target_smoothing)


	return current_grouping_position - base_target
	


func check_state() -> State:
	
	return null


# Settings integration
func config_changed():
	update_settings_from_config()

func update_settings_from_config():
	# Use lookahead toggle
	var la = _config.get_setting("camera_lookahead")
	if la != null:
		Use_Lookahead = bool(la)
	
	# Camera speed (1-5)
	var idx = int(_config.get_setting("camera_speed"))
	if idx <= 0:
		idx = 3
	_camera_speed_index = clamp(idx, 1, 5)
	_camera_speed_scale = _camera_speed_to_scale(_camera_speed_index)
	
	# Apply effective speeds
	Effective_Maximum_Speed = _base_max_speed * _camera_speed_scale
	Effective_Minimum_Speed = _base_min_speed * _camera_speed_scale
	Effective_BaseAcceleration = _base_accel * _camera_speed_scale
	# Update current accel immediately so changes take effect mid-run
	accel = Effective_BaseAcceleration
	
	# Lookahead distance preset (1–5)
	var dist_idx = int(_config.get_setting("lookahead_distance"))
	if dist_idx <= 0:
		dist_idx = 2
	Lookahead_Max_Offset_X = _lookahead_index_to_offset(clamp(dist_idx, 1, 5))

func _camera_speed_to_scale(idx: int) -> float:
	match idx:
		1:
			return 0.75
		2:
			return 0.9
		3:
			return 1.0
		4:
			return 1.2
		5:
			return 1.5
		_:
			return 1.0

func _lookahead_index_to_offset(idx: int) -> float:
	# Map 1–5 to subtle → far
	match idx:
		1:
			return 12.0
		2:
			return 18.0
		3:
			return 30.0
		4:
			return 40.0
		5:
			return 48.0
		_:
			return Lookahead_Max_Offset_X
