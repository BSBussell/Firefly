@tool
extends Node

@export var lut_size := 16
@export var save_identity_lut := false

var identity_lut_image: Image = null


func _enter_tree():
	ensure_identity_lut()


func _unhandled_input(event):
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F11:
		generate_lut_screenshot()


func generate_lut_screenshot():
	var screenshot = take_screenshot()
	var identity_lut = ensure_identity_lut()
	var final_image_size = Vector2i(max(screenshot.get_width(), identity_lut.get_width()), max(screenshot.get_height(), identity_lut.get_height()))
	var final_image := Image.new()
	final_image.create(final_image_size.x, final_image_size.y, false, Image.FORMAT_RGB8)
	insert_image(final_image, screenshot)
	insert_image(final_image, identity_lut)
	var result = final_image.save_png("res://screenshot_lut.png")
	if result != OK:
		push_warning("COLOR GRADING LUT: Unable to save LUT screenshot PNG (error code %d)." % result)
	else:
		print("COLOR GRADING LUT: Screenshot with LUT of size %d was successfully created!\nTarget path: res://screenshot_lut.png" % lut_size)
	if save_identity_lut:
		var identity_result = identity_lut.save_png("res://identity_lut_%d.png" % lut_size)
		if identity_result != OK:
			push_warning("COLOR GRADING LUT: Unable to save identity LUT PNG (error code %d)." % identity_result)


func take_screenshot():
	var image = get_viewport().get_texture().get_image()
	image.flip_y()
	return image


func insert_image(target, inserted):
	inserted.lock()
	target.lock()
	for x in range(inserted.get_width()):
		for y in range(inserted.get_height()):
			target.set_pixel(x, y, inserted.get_pixel(x, y))
	inserted.unlock()
	target.unlock()


func generate_identity_lut(size):
	var image := Image.new()
	image.create(size * size, size, false, Image.FORMAT_RGB8)
	image.lock()
	var div_step = 1.0 / float(size - 1)
	for b in range(size):
		for g in range(size):
			for r in range(size):
				var x = r + size * b
				var color = Color(float(r), float(g), float(b)) * div_step
				color.a = 1.0
				image.set_pixel(x, g, color)
	image.unlock()
	return image


func ensure_identity_lut():
	if identity_lut_image == null or identity_lut_image.get_width() != lut_size * lut_size:
		var size = max(lut_size, 2)
		identity_lut_image = generate_identity_lut(size)
		lut_size = size
	return identity_lut_image
