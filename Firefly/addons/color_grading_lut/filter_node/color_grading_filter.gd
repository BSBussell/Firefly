@tool
extends ColorRect

@export var lut: Texture2D

var shader_material: ShaderMaterial = null


func _ready():
	_initialize_material()
	_initialize_layout()
	_refresh_lut()
	_refresh_filter_alpha()
	set_process(true)


func _process(_delta):
	_refresh_filter_alpha()


func _initialize_material():
	if shader_material == null:
		shader_material = ShaderMaterial.new()
		material = shader_material
	if shader_material.shader == null:
		shader_material.shader = load("res://addons/color_grading_lut/filter_node/color_grading_lut.shader")
	if lut == null:
		lut = load("res://addons/color_grading_lut/default_luts/identity.png")


func _initialize_layout():
	anchor_left = 0.0
	anchor_right = 1.0
	anchor_top = 0.0
	anchor_bottom = 1.0
	offset_left = 0.0
	offset_right = 0.0
	offset_top = 0.0
	offset_bottom = 0.0


func _refresh_lut():
	if shader_material == null or lut == null:
		return
	shader_material.set_shader_parameter("lut", lut)


func _refresh_filter_alpha():
	if shader_material == null:
		return
	shader_material.set_shader_parameter("filter_alpha", color.a)
