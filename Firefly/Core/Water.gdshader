shader_type canvas_item;
render_mode blend_mix,unshaded;

uniform float transparency : hint_range(0, 1) = 1.0;

uniform vec4 color0 : source_color;
uniform vec4 color1 : source_color;
uniform vec4 color2 : source_color;
uniform vec4 color3 : source_color;
uniform vec4 color4 : source_color;
uniform vec4 color5 : source_color;

uniform vec2 Direction1 = vec2(1, 0); 
uniform vec2 Direction2 = vec2(1, 1); 
uniform float Speed1 = 0.08;
uniform float Speed2 = 0.08;
uniform sampler2D noise;
uniform int pixel_size;

uniform float heatAmplitude : hint_range(0.0, 0.15);
uniform float heatPeriod;
uniform float heatPhaseShift;
uniform float heatUpperLimit : hint_range(0.5, 10.0);

vec4 get_pixelated_moving_colors(vec2 uv, vec2 direction, float speed) {
	speed = speed / 1000.0;
	vec2 moving_uv = uv + (direction * TIME * speed);
	vec2 pixel_uv = round((moving_uv) * float(pixel_size)) / float(pixel_size);
	vec4 pixelated_color = texture(noise, pixel_uv);
	return pixelated_color;
}

bool is_in_threshold(vec4 old_color, float threshold_low, float threshold_hi){
	if(threshold_low <= old_color.r + old_color.g + old_color.b && old_color.r + old_color.g + old_color.b < threshold_hi) {
        return true;
    } else {
		return false;
	}
}

vec4 smooth_extreme_colors(vec4 color) {
	// Lower numbers are darker
	float threshold_1 = 1.7;
	float threshold_2 = 1.9;
	float threshold_3 = 2.2;
	float threshold_4 = 2.25;
	float threshold_5 = 2.3;
	// Dark to light
	if (is_in_threshold(color, 0, threshold_1)) {
        color = color0;
    } else if (is_in_threshold(color, threshold_1, threshold_2)) {
        color = color1;
    } else if (is_in_threshold(color, threshold_2, threshold_3)) {
        color = color2;
    } else if (is_in_threshold(color, threshold_3, threshold_4)) {
        color = color3;
	} else if (is_in_threshold(color, threshold_4, threshold_5)) {
        color = color4;
    } else if (is_in_threshold(color, threshold_5, 3.0)) {
        color = color5;
    }
	
	return color;
}


void fragment(){
	
	vec4 pixelated_color = .5 * get_pixelated_moving_colors(UV, Direction1, Speed1);
	pixelated_color += .5 * get_pixelated_moving_colors(UV, Direction2, Speed2);
	vec4 smoothed_color = smooth_extreme_colors(pixelated_color);
	
	COLOR = smoothed_color * transparency;

}