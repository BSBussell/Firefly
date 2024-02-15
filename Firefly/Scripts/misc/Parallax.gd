extends Node2D

# Exported variables to set the sprites and the follow target
@export var Player: Node2D
@export var layer1_parallax_strength = 0.05
@export var godrays_parallax_strength = 0.075
@export var layer2_parallax_strength = 0.1
@export var layer3_parallax_strength = 0.125
@export var layer4_parallax_strength = 0.15

# Onready vars to cache the layers and follow target
@onready var layer1 = $"Layer 1"
@onready var godrays = $"GodRays"
@onready var layer2 = $"Layer 2"
@onready var layer3 = $"Layer 3"
@onready var layer4 = $"Layer 4"

# You might want to adjust the parallax strength for vertical movement, potentially different from horizontal movement
@export var vertical_parallax_strength_modifier = 0.0

@onready var camera = Player.get_node("Camera2D")


var previous_camera_pos = Vector2()


# The original positions of the layers for reset purposes
var original_positions = {}

func _ready():
	# Cache the original positions
	original_positions["layer1"] = layer1.position
	original_positions["godrays"] = godrays.position
	original_positions["layer2"] = layer2.position
	original_positions["layer3"] = layer3.position
	original_positions["layer4"] = layer4.position

func _process(delta):
	if camera and camera.global_position != previous_camera_pos:
		print("Camera move")
		update_parallax()
		previous_camera_pos = camera.global_position


func update_parallax():
	var follow_pos = camera.global_position
	# Adjust for vertical movement
	var vertical_adjustment = follow_pos.y * vertical_parallax_strength_modifier
	layer1.position = original_positions["layer1"] + Vector2(follow_pos.x * layer1_parallax_strength, vertical_adjustment)
	godrays.position = original_positions["godrays"] + Vector2(follow_pos.x * godrays_parallax_strength, vertical_adjustment)
	layer2.position = original_positions["layer2"] + Vector2(follow_pos.x * layer2_parallax_strength, vertical_adjustment)
	layer3.position = original_positions["layer3"] + Vector2(follow_pos.x * layer3_parallax_strength, vertical_adjustment)
	layer4.position = original_positions["layer4"] + Vector2(follow_pos.x * layer4_parallax_strength, vertical_adjustment)
