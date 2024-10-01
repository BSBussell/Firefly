class_name AnimatedToggle
extends Button

signal switched_on
signal switched_off

@export var sprite_size = Vector2(7,4)

@onready var animated_sprite_2d = $AnimatedSprite2D

#var theme_scale: float = 25.0 setget set_custom_scale

var base_Scale: float = 1.0
var hover_Scale: float = 1.0

var theme_mod: Color
var theme_hover_mod: Color


var toggle: bool = false

func _ready():  
	
	_config.connect_to_config_changed(Callable(self, "config_changed"))

	
	#refresh_focus()
	_apply_theme()
	
	animated_sprite_2d.modulate = theme_mod
	set_theme_scale(base_Scale)
	pass


func set_theme_scale(scale_val):
	custom_minimum_size = sprite_size * scale_val
	
	animated_sprite_2d.position = custom_minimum_size/2
	animated_sprite_2d.scale = Vector2(scale_val, scale_val)

func _apply_theme():
	
	base_Scale = get_theme_constant("scale", "AnimatedToggle")
	hover_Scale = get_theme_constant("hover_scale", "AnimatedToggle")
	
	theme_mod = get_theme_color("modulate", "AnimatedToggle")
	theme_hover_mod = get_theme_color("hover_modulate", "AnimatedToggle")
	
	
	
	

## A function in case i ever need to do this again
#func refresh_focus():
	## Setup focus neighbors because our thing involes
	#if focus_neighbor_left:
		#button.focus_neighbor_left = NodePath( "../" + str(focus_neighbor_left))
	#if focus_neighbor_top:
		#button.focus_neighbor_top = NodePath( "../" + str(focus_neighbor_top))
	#if focus_neighbor_right:
		#button.focus_neighbor_right = NodePath( "../" + str(focus_neighbor_right))
	#if focus_neighbor_bottom:
		#button.focus_neighbor_bottom = NodePath( "../" + str(focus_neighbor_bottom))

func _on_pressed():
	
	if toggle:
		toggle_off()
	else:
		toggle_on()

func toggle_on():
	animated_sprite_2d.play("On")
	toggle = true
	emit_signal("switched_on")

func toggle_off():
	animated_sprite_2d.play("Off")
	toggle = false
	emit_signal("switched_off")

func _on_focus_entered():
	
	_apply_theme()
	
	animated_sprite_2d.modulate = theme_hover_mod
	set_theme_scale(hover_Scale)
	#animated_sprite_2d.scale = Vector2(hover_Scale, hover_Scale)




func _on_focus_exited():
	
	_apply_theme()
	
	# Set the sprite back to looking lame asf
	animated_sprite_2d.modulate = theme_mod
	set_theme_scale(base_Scale)
	#animated_sprite_2d.scale = Vector2(base_Scale, base_Scale)
	
func config_changed():
	
	_apply_theme()
	set_theme_scale(base_Scale)
