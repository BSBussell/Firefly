shader_type canvas_item;

// Used in order to give a small subpixel offset for camera movements
uniform vec2 sub_pixel_offset = vec2(0.0, 0.0);


void vertex() {
	// Called for every vertex the material is visible on.
	VERTEX += sub_pixel_offset;
}


//void light() {
	// Called for every pixel for every light affecting the CanvasItem.
	// Uncomment to replace the default light processing function with this one.
//}
