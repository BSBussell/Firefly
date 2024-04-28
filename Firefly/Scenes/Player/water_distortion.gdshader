shader_type canvas_item;

// Uniforms
uniform sampler2D noise_tex;
uniform float distortion_strength = 5.0;  // Adjust to get desired distortion effect
uniform vec4 tint_color: source_color; // Default to white (no tint)

uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_linear;

void fragment() {
    // Base UV coordinates
    vec2 uv = FRAGCOORD.xy / SCREEN_PIXEL_SIZE;

    // Noise for offset
    vec2 noise_value = texture(noise_tex, uv * 0.1).rg;  // Scale the UVs to control noise frequency
    noise_value = (noise_value - 0.5) * 2.0;  // Normalize to -1 to 1 range

    // Calculate offset
    vec2 offset = noise_value * distortion_strength;

    // Snap coordinates to nearest pixel
    vec2 pixel_uv = (floor(uv + offset) + 0.5) / (SCREEN_PIXEL_SIZE);

    // Sample the screen texture with snapped coordinates
    vec4 color = texture(SCREEN_TEXTURE, pixel_uv);

    // Apply the tint
    color.rgb *= tint_color.rgb;
    color.a *= tint_color.a;

    // Output the final color
    COLOR = color;
}
