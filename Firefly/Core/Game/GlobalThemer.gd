extends Control
class_name GlobalThemer

var base_theme: Theme

var BASE_RESOLUTION: Vector2 = Vector2(1920,1200)


# Called when the node enters the scene tree for the first time.
func _ready():
	base_theme = theme.duplicate()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func scale_theme(resolution: Vector2):
	
	var scale_factor: float = resolution.x / BASE_RESOLUTION.x
	
	# AnimatedToggle
	scale_elem_constant_by("AnimatedToggle", "hover_scale", scale_factor)
	scale_elem_constant_by("AnimatedToggle", "scale", scale_factor)
	
	# UI_Jar
	scale_elem_constant_by("UI_Jar", "scale", scale_factor)
	
	# TextureProgressMeter
	scale_elem_constant_by("TextureProgressBar", "scale", scale_factor)
	
	
	# File Select Buttons
	scale_elem_font_by("NameEntryButton", scale_factor)
	scale_elem_font_by("FileButtons", scale_factor)
	
	# File Select Lebal
	scale_elem_font_by("FileLabel", scale_factor)
	scale_elem_font_by("FileJarCount", scale_factor)
	scale_elem_font_by("FileTime", scale_factor)

	# File Select Name Entry
	scale_elem_font_by("LineEdit", scale_factor)
	
	
	# Button
	scale_elem_font_by("Button", scale_factor)
	# CounterLabel - label
	scale_elem_font_by("CounterLabel", scale_factor)
	# HeaderLarge - label
	scale_elem_font_by("HeaderLarge", scale_factor)
	# Label
	scale_elem_font_by("Label", scale_factor)
	# PauseHeader - label
	scale_elem_font_by("PauseHeader", scale_factor)
	# RichTextLabel
	scale_rich_elem_font_by("RichTextLabel", scale_factor)
	# SettingHeader - label
	scale_elem_font_by("SettingHeader", scale_factor) 
	
	# Level Title
	scale_elem_font_by("LevelTitle", scale_factor)
	
	# Timer Text
	scale_elem_font_by("TimerText", scale_factor)
	
	# HSlider Thickness
	scale_elem_constant_by("HSlider", "thickness", scale_factor)
	scale_elem_constant_by("HSlider", "focused_thickness", scale_factor)
	pass
	
func scale_elem_constant_by(elem_name: String, prop_name: String, scale_factor: float):
	
	# Retrieve the base font size from the theme
	var base_val: int = base_theme.get_constant(prop_name, elem_name)
	
	# Check if the base font size was retrieved successfully
	if base_val == 0:
		print("Base font size for", elem_name, "not found! Check if theme is set correctly.")
		return
	
	# Apply the scaling factor
	var scaled_val: int = int(base_val * scale_factor)
	
	# Add the scaled value as an override
	theme.set_constant(prop_name, elem_name, scaled_val)

func scale_elem_font_by(elem_name: String, scale_factor: float):
	
	
	# Retrieve the base font size from the theme
	var base_font: int = base_theme.get_font_size("font_size", elem_name)
	
	# Check if the base font size was retrieved successfully
	if base_font == 0:
		print("Base font size for", elem_name, "not found! Check if theme is set correctly.")
		return
	
	# Apply the scaling factor
	var scaled_font: int = int(base_font * scale_factor)
	
	# Add the scaled value as an override
	theme.set_font_size("font_size", elem_name, scaled_font)
	

func scale_rich_elem_font_by(elem_name: String, scale_factor: float):
	
	
	# Retrieve the base font size from the theme
	var base_font: int = base_theme.get_font_size("normal_font_size", elem_name)
	
	# Check if the base font size was retrieved successfully
	if base_font == 0:
		print("Base font size for", elem_name, "not found! Check i f theme is set correctly.")
		return
	
	# Apply the scaling factor
	var scaled_font: int = int(base_font * scale_factor)
	
	# Add the scaled value as an override
	theme.set_font_size("normal_font_size", elem_name, scaled_font)
	
	


