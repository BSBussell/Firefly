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
	
	_viewports.viewer.connect_to_res_changed(Callable(self, "config_changed"))

	_apply_theme()
	
	animated_sprite_2d.modulate = theme_mod
	set_theme_scale(base_Scale)
	pass


func set_theme_scale(scale_val):
	animated_sprite_2d.scale = Vector2(scale_val, scale_val)

func _apply_theme():
	
	base_Scale = get_theme_constant("scale", "AnimatedToggle")
	hover_Scale = get_theme_constant("hover_scale", "AnimatedToggle")
	
	theme_mod = get_theme_color("modulate", "AnimatedToggle")
	theme_hover_mod = get_theme_color("hover_modulate", "AnimatedToggle")
	
	
	
	
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
	
	animated_sprite_2d.modulate = theme_hover_mod
	set_theme_scale(hover_Scale)


func _on_focus_exited():
	
	# Set the sprite back to looking lame asf
	animated_sprite_2d.modulate = theme_mod
	set_theme_scale(base_Scale)
	
func config_changed():
	
	# For some reason it takes awhile for the theme to update after its been changed in parent i can't tell you why
	await get_tree().create_timer(0.001).timeout
	
	if animated_sprite_2d.scale.x == base_Scale:
	
		_apply_theme()
		set_theme_scale(base_Scale)
		
	else:
		
		_apply_theme()
		set_theme_scale(hover_Scale)
