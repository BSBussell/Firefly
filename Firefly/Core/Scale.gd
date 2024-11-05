extends Control

@export var high_dpi_scale: Vector2 = Vector2(2, 2)

@export_category("Offsets")
@export var custom_offsets: bool = false


@onready var base_scale: Vector2 = scale
@onready var base_lr_offset: Vector2 =  Vector2(offset_left, offset_right)
@onready var base_tb_offset: Vector2 = Vector2(offset_top, offset_bottom)

# Called when the node enters the scene tree for the first time.
func _ready():
	
	_config.connect_to_config_changed(Callable(self,"config_changed"))
	config_changed()


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
	#var current_resolution = DisplayServer.window_get_size()
#
	#if current_resolution.x > 1920:
		#scale = high_dpi_scale
		#
		#if custom_offsets:
			#offset_left *= (high_dpi_scale.x/base_scale.x)
			#offset_right *= (high_dpi_scale.x/base_scale.x)
			#offset_top *= (high_dpi_scale.y/base_scale.y)
			#offset_bottom *= (high_dpi_scale.y/base_scale.y)
		#
	#else:
		#scale = base_scale
		#
		#if custom_offsets:
			#offset_left = base_lr_offset.x
			#offset_right = base_lr_offset.y
			#offset_top = base_tb_offset.x
			#offset_bottom = base_tb_offset.y

func config_changed():
	
	var current_resolution = DisplayServer.window_get_size()

	if current_resolution.x > 1920:
		
		scale = high_dpi_scale
		
		if custom_offsets:
			offset_left = base_lr_offset.x * (high_dpi_scale.x/base_scale.x)
			offset_right = base_lr_offset.y * (high_dpi_scale.x/base_scale.x)
			offset_top = base_tb_offset.x * (high_dpi_scale.y/base_scale.y)
			offset_bottom = base_tb_offset.y * (high_dpi_scale.y/base_scale.y)
		
	else:
		
		scale = base_scale
		
		if custom_offsets:
			offset_left = base_lr_offset.x
			offset_right = base_lr_offset.y
			offset_top = base_tb_offset.x
			offset_bottom = base_tb_offset.y
