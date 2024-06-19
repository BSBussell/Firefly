shader_type canvas_item;

uniform float swipe_progress : hint_range(0.0, 1.0) = 0.0;
uniform vec4 swipe_color = vec4(0.0, 0.0, 0.0, 3.0);

void fragment() {
    vec2 uv = FRAGCOORD.xy / SCREEN_PIXEL_SIZE.xy;
    if (uv.x < swipe_progress) {
        COLOR = texture(TEXTURE, FRAGCOORD.xy / TEXTURE_PIXEL_SIZE);
    } else {
        COLOR = swipe_color;
    }
}
