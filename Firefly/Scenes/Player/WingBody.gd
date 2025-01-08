extends Node2D


@export_subgroup("Exterior Objs")
@export var sprite: AnimatedSprite2D

@onready var flyph = $"../../.."


func _ready():
	sprite.connect("property_list_changed", Callable(self, "sprite_changed"))
	
	
func _process(_delta):
	if sprite.flip_h:
		position.x = 3
	else:
		position.x = -3
		
	if flyph.can_glide:
		modulate.a = 255
	
func sprite_changed():
	
	pass
	
		
