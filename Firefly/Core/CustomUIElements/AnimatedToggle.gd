class_name AnimatedToggle
extends Control

signal switched_on
signal switched_off


@onready var animated_sprite_2d = $AnimatedSprite2D

@onready var button: Button = $button
var toggle: bool = false

func _ready():
	
	refresh_focus()


# A function in case i ever need to do this again
func refresh_focus():
	# Setup focus neighbors because our thing involes
	if focus_neighbor_left:
		button.focus_neighbor_left = NodePath( "../" + str(focus_neighbor_left))
		print(button.focus_neighbor_left)
	if focus_neighbor_top:
		button.focus_neighbor_top = NodePath( "../" + str(focus_neighbor_top))
	if focus_neighbor_right:
		button.focus_neighbor_right = NodePath( "../" + str(focus_neighbor_right))
	if focus_neighbor_bottom:
		button.focus_neighbor_bottom = NodePath( "../" + str(focus_neighbor_bottom))

func _on_pressed():
	if toggle:
		animated_sprite_2d.play("Off")
		toggle = false
		emit_signal("switched_off")
	else:
		animated_sprite_2d.play("On")
		toggle = true
		emit_signal("switched_on")


func _on_focus_entered():
	
	print("Focus Entered")
	
	animated_sprite_2d.modulate = "#FFFFFF"
	
	# Pass the focus to the button :3
	button.grab_focus()


func _on_button_focus_exited():
	
	# Set the sprite back to looking lame asf
	animated_sprite_2d.modulate = "#8f8f8f"
