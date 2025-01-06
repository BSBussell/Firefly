shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D normal_map : hint_normal; // Normal map for surface detail

uniform vec4 tint_color : source_color = vec4(1.0, 1.0, 1.0, 0.5); // Base transparency
uniform float glossiness : hint_range(0.0, 1.0) = 0.6; // Reflective strength
uniform float highlight_size : hint_range(0.0, 1.0) = 0.5; // Highlight size
uniform vec2 light_dir = vec2(1.0, -1.0); // Direction of light

void fragment() {
    vec2 uv_centered = UV - vec2(0.5); // Center UV coordinates
    float dist = length(uv_centered) * 2.0; // Distance from center for radial effect

    // Base transparency with a soft fade-out toward the edges
    float alpha = smoothstep(1.0, 0.8, dist);
    alpha *= tint_color.a;

    // Simulate a glass highlight based on light direction and UV
    vec2 light = normalize(light_dir);
    float highlight = dot(normalize(uv_centered), light);
    highlight = smoothstep(1.0 - highlight_size, 1.0, highlight);

    // Combine base color with highlights
    vec3 color = tint_color.rgb + vec3(highlight * glossiness);

    // Set the fragment output
    COLOR = vec4(color, alpha);
}