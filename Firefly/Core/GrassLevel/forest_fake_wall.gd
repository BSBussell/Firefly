extends TileMap

@export var Player: Node2D
@export var spotlight_radius: float = 64.0
@export var fade_radius: float = 10.0

# Dynamic radius based on tile proximity
@export_group("Dynamic Radius")
@export var enable_dynamic_radius: bool = true
@export var min_radius: float = 32.0
@export var max_radius: float = 128.0
@export var detection_distance: float = 5.0
@export var check_directions: int = 8
@export var smooth_transition: float = 0.1
@export var tilemap_layer: int = 0
@export var check_all_layers: bool = false

# Performance settings
@export_group("Premature-Optimization")
@export var tile_check_frequency: float = 0.016  # Check tiles every N seconds instead of every frame
@export var parameter_update_frequency: float = 0.016  # Update shader params every N seconds
@export var distance_cache_timeout: float = 0.1  # Cache distance results for N seconds

# Stylization options
@export_group("Pixel Art Style")
@export var pixelated_edge: bool = true
@export var edge_steps: int = 8
@export var animated_edge: bool = false
@export var animation_speed: float = 1.0
@export var dithering: bool = false
@export var fog_color: Color = Color(0.1, 0.1, 0.2)
@export var fog_blend: float = 0.3

# Wobbly options
@export_group("Organic Wobbliness")
@export var wobbliness: float = 0.0
@export var wobble_frequency: float = 2.0
@export var wobble_speed: float = 1.0
@export var wobble_octaves: int = 2

var shader_mat: ShaderMaterial
var current_radius: float
var target_radius: float

# Performance optimization variables
var last_tile_check_time: float = 0.0
var last_parameter_update_time: float = 0.0
var cached_distance: float = 0.0
var cached_distance_time: float = 0.0
var last_player_tile_pos: Vector2i = Vector2i.MAX
var dirty_parameters: bool = true

# Direction vectors (cached)
var directions_4 = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
var directions_8 = [
	Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
	Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)
]

# Cached shader parameters to avoid unnecessary updates
var cached_shader_params: Dictionary = {}

func _ready():
	shader_mat = material as ShaderMaterial
	current_radius = spotlight_radius
	target_radius = spotlight_radius
	
	if shader_mat:
		force_update_all_shader_parameters()

func has_tile_at_position(pos: Vector2i) -> bool:
	if check_all_layers:
		for layer in range(get_layers_count()):
			var source_id = get_cell_source_id(layer, pos)
			if source_id != -1:
				return true
		return false
	else:
		var source_id = get_cell_source_id(tilemap_layer, pos)
		return source_id != -1

func get_closest_tile_distance_cached() -> float:
	if not Player:
		return detection_distance
	
	var current_time = Time.get_ticks_msec() / 1000.0
	var player_tile_pos = local_to_map(to_local(Player.global_position))
	
	# Use cached result if player hasn't moved tiles and cache is still valid
	if player_tile_pos == last_player_tile_pos and (current_time - cached_distance_time) < distance_cache_timeout:
		return cached_distance
	
	# Update cache
	last_player_tile_pos = player_tile_pos
	cached_distance_time = current_time
	cached_distance = calculate_closest_tile_distance()
	
	return cached_distance

func calculate_closest_tile_distance() -> float:
	var player_tile_pos = last_player_tile_pos
	var directions = directions_8 if check_directions == 8 else directions_4
	var min_distance = INF
	
	# Early exit optimization: check immediate neighbors first
	for direction in directions:
		if has_tile_at_position(player_tile_pos + direction):
			return 1.0  # Found tile immediately adjacent
	
	# Check further distances only if needed
	for direction in directions:
		var current_pos = player_tile_pos
		var distance = 0.0
		
		for i in range(2, int(detection_distance) + 1):  # Start from 2 since we checked 1 above
			current_pos += direction
			distance += 1.0
			
			if has_tile_at_position(current_pos):
				min_distance = min(min_distance, distance)
				break
	
	return min_distance if min_distance != INF else detection_distance

func calculate_dynamic_radius() -> float:
	if not enable_dynamic_radius:
		return spotlight_radius
	
	var closest_distance = get_closest_tile_distance_cached()
	var distance_ratio = closest_distance / detection_distance
	distance_ratio = 1.0 - clamp(distance_ratio, 0.0, 1.0)
	
	return lerp(min_radius, max_radius, distance_ratio)

func set_shader_parameter_cached(param_name: String, value):
	if not shader_mat:
		return
		
	# Only update if value changed
	if not cached_shader_params.has(param_name) or cached_shader_params[param_name] != value:
		shader_mat.set_shader_parameter(param_name, value)
		cached_shader_params[param_name] = value

func update_shader_parameters():
	if not shader_mat:
		return
	
	set_shader_parameter_cached("spotlight_radius", current_radius)
	set_shader_parameter_cached("fade_radius", fade_radius)
	set_shader_parameter_cached("pixelated_edge", pixelated_edge)
	set_shader_parameter_cached("edge_steps", edge_steps)
	set_shader_parameter_cached("animated_edge", animated_edge)
	set_shader_parameter_cached("animation_speed", animation_speed)
	set_shader_parameter_cached("dithering", dithering)
	set_shader_parameter_cached("fog_color", Vector3(fog_color.r, fog_color.g, fog_color.b))
	set_shader_parameter_cached("fog_blend", fog_blend)
	set_shader_parameter_cached("wobbliness", wobbliness)
	set_shader_parameter_cached("wobble_frequency", wobble_frequency)
	set_shader_parameter_cached("wobble_speed", wobble_speed)
	set_shader_parameter_cached("wobble_octaves", wobble_octaves)

func force_update_all_shader_parameters():
	cached_shader_params.clear()
	update_shader_parameters()
	dirty_parameters = false

func _process(delta):
	if not Player or not shader_mat:
		return
	
	var current_time = Time.get_ticks_msec() / 1000.0
	
	# Update tile distance check at reduced frequency
	if current_time - last_tile_check_time >= tile_check_frequency:
		target_radius = calculate_dynamic_radius()
		last_tile_check_time = current_time
	
	# Always update current radius for smooth transitions
	if smooth_transition > 0:
		current_radius = lerp(current_radius, target_radius, smooth_transition)
	else:
		current_radius = target_radius
	
	# Get player position and update screen position (this needs to be every frame)
	var camera = get_viewport().get_camera_2d()
	if not camera:
		return
	
	var player_global_pos = Player.global_position
	var camera_pos = camera.get_screen_center_position()
	var viewport_size = get_viewport().get_visible_rect().size
	var zoom = camera.zoom
	
	var player_screen_pos = (player_global_pos - camera_pos) * zoom + viewport_size * 0.5
	
	# Always update positions (they change every frame when moving)
	shader_mat.set_shader_parameter("player_screen_pos", player_screen_pos)
	shader_mat.set_shader_parameter("player_world_pos", player_global_pos)
	
	# Update other parameters at reduced frequency
	if current_time - last_parameter_update_time >= parameter_update_frequency or dirty_parameters:
		update_shader_parameters()
		last_parameter_update_time = current_time
		dirty_parameters = false

# Call this when you change export parameters at runtime
func mark_parameters_dirty():
	dirty_parameters = true
