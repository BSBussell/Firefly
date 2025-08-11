extends CPUParticles2D

@export var Disable_Camera_Target: bool = false
@onready var Camera_Target: CameraTarget = $Area2D

@export_group("CameraTarget Props")
## How much weight the target will have when averaged with other targets
@export var pull_strength: float = 1.0

## How much of a priority the targets "blend_override" will be relative to
## other targets. -1 does not override the blend
@export var blend_priority: int = -1

## The location between the player and other targets that the camera will rest in.
## The camera will take the average location of all targets on screen, then it 
## will draw a line between the player to that location. The blend_override sets 
## What ratio from the player to that location the camera will center on, 0.0 is
## the player, 1.0 is the averaged location.
@export var blend_override: float = 0.3

## Update Base Camera Acceleration. 
@export var target_snap: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	if Disable_Camera_Target:
		Camera_Target.disable_target()
		
	else:
		
		Camera_Target.pull_strength = pull_strength
		Camera_Target.blend_priority = blend_priority
		Camera_Target.blend_override = blend_override
		Camera_Target.target_snap = target_snap


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
