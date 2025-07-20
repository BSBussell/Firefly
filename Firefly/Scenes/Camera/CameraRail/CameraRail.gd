extends Path2D
class_name CameraRail

@export var ActivationArea: Area2D

# ACTIVE: when the player is near the rail
@export var STIFFNESS_ACTIVE:    float = 150.0
# INACTIVE: when the player is too far/speedy
@export var STIFFNESS_INACTIVE:  float = 800.0

@export var MAX_ACTIVE_DISTANCE: float = 250.0
@export var MAX_ACTIVE_SPEED:    float = 600.0

@onready var follow_node:   PathFollow2D = $FollowNode

@onready var camera_target: CameraTarget = $FollowNode/CameraTarget

@onready var debug_sprite = $FollowNode/Sprite2D
@onready var dist = $FollowNode/Sprite2D/Dist



var player:    Flyph = null
var cam_vel:   float = 0.0  # spring velocity


func _ready():
	if ActivationArea:
		ActivationArea.connect("body_entered",  Callable(self, "_on_player_in"))
		ActivationArea.connect("body_exited",   Callable(self, "_on_player_out"))
	else:
		push_error("CameraRail: ActivationArea not set!")
	

var player_died: bool = false

func _process(delta):
	
	
	if not player:
		return
		
	if not (curve and curve.get_point_count() > 0):
		push_error("CameraRail: Curve missing points!")
		return
		
	if player.dying:
		camera_off(.15)
		player_died = true
	elif player_died:
		player_died = false
		check_if_player_inside(player)
	
		
		

	var local_pos    = to_local(player.global_position)
	var closest_off  = curve.get_closest_offset(local_pos)
	if !is_finite(closest_off):
		push_error("CameraRail: invalid offset!")
		return

	var rail_pt      = curve.sample_baked(closest_off)
	var dist_to_rail = (rail_pt - local_pos).length()
	var speed        = player.velocity.length()
	var is_active    = dist_to_rail <= MAX_ACTIVE_DISTANCE and speed <= MAX_ACTIVE_SPEED
	
	dist.text = str(roundf(dist_to_rail))

	var k = STIFFNESS_ACTIVE if is_active else STIFFNESS_INACTIVE
	var c = 2.0 * sqrt(k)  # critical damping

	var force      = k * (closest_off - follow_node.progress)
	var damp_force = -c * cam_vel
	cam_vel += (force + damp_force) * delta
	follow_node.progress += cam_vel * delta


		


func _on_player_in(body, speed: float = 1.0):
	if not (body is Flyph):
		return
	player = body
	cam_vel = 0.0
	
	var local_pos    = to_local(player.global_position)
	var closest_off  = curve.get_closest_offset(local_pos)
	
	follow_node.progress = closest_off

	# reset starting values
	camera_target.blend_override = 0.3
	camera_target.pull_strength  = 0.0
	camera_target.enable_target()
	
	camera_on(speed)
	
	
	
	
	
	

func _on_player_out(body):
	if not (body is Flyph):
		return

	camera_off()
	

var camera_tween: Tween = null

var smooth_time: float = 0.75 
func camera_on(speed: float = 1):
	
	camera_target.enable_target()
	
	print("Enabling Target")
	
	# kill old tweens first
	if camera_tween and camera_tween.is_valid():
		camera_tween.kill()
	
	# build a parallel tween
	camera_tween = create_tween().set_parallel(true)

	# note: 1) object, 2) property path, 3) final value, 4) duration
	camera_tween.tween_property(camera_target, "blend_override", 1.0, smooth_time / speed) \
	  .set_trans(Tween.TRANS_SINE) \
	  .set_ease(Tween.EASE_IN_OUT)

	camera_tween.tween_property(camera_target, "pull_strength", 1000.0, smooth_time / speed) \
	  .set_trans(Tween.TRANS_SINE) \
	  .set_ease(Tween.EASE_IN_OUT)
	
	# Interpolate the true :3
	camera_tween.tween_property(camera_target, "target_snap", true, (smooth_time*3) / speed) \
	  .set_trans(Tween.TRANS_SINE) \
	  .set_ease(Tween.EASE_IN_OUT)
	
	camera_tween.tween_property(self, "modulate", Color(1.0,1.0,1.0,1.0), smooth_time / speed) \
	  .set_trans(Tween.TRANS_LINEAR)
	
	
	
func camera_off(speed: float = 1.0):
	
	print("Disabling Target")
	
	# kill old tweens first
	if camera_tween and camera_tween.is_valid():
		camera_tween.kill()
		
	camera_target.target_snap = false
	
	camera_tween = create_tween().set_parallel(true)
	camera_tween.tween_property(camera_target, "blend_override", 0.3, smooth_time / speed) \
	  .set_trans(Tween.TRANS_LINEAR) \
	  .set_ease(Tween.EASE_IN_OUT)
	camera_tween.tween_property(camera_target, "pull_strength",  20, (smooth_time) / speed) \
	  .set_trans(Tween.TRANS_SINE) \
	  .set_ease(Tween.EASE_IN_OUT)
	camera_tween.tween_property(self, "modulate", Color(1,1,1,0.0), (smooth_time) / speed) \
	  .set_trans(Tween.TRANS_LINEAR)
	
	
	
	camera_tween.tween_callback(Callable(camera_target, "disable_target")).set_delay((smooth_time) / speed)




func _on_activation_area_body_entered(body):
	
	# Check if body is of type Flyph
	if body is Flyph:
		
		print("Player In")
		_on_player_in(body)
	else:
		print("Not a Flyph")
	
	

func _on_activation_area_body_exited(body):
	
	# Check if body is of type Flyph
	if body is Flyph:
		
		print("Player Left")
		_on_player_out(body)
		
	else:
		print("Not a Flyph")
	
	
func check_if_player_inside(p):
	# Check manually if the player's new position is inside this rail's ActivationArea
	if ActivationArea and ActivationArea.get_overlapping_bodies().has(p):
		_on_player_in(p, 0.15)
	

