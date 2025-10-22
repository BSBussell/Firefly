shader_type canvas_item;

/*
    Spotlight circle transition (no feathering, perfect circle).
    - At progress = 0.0, the circle covers the entire screen/rect.
    - At progress = 1.0, the circle closes to a point at center_screen_uv.
    - Circle measured in SCREEN PIXELS to avoid oval distortion.
*/

uniform bool use_sprite_alpha = true;   // Respect the drawn sprite's alpha (or ColorRect alpha)
uniform bool invert = false;            // If true, invert mask (outside the circle instead of inside)
uniform float progress : hint_range(0.0, 1.0) = 0.0;

/* Center of the spotlight in SCREEN UV (0..1 across the viewport).
   If you want it relative to your rect, compute it in script:
   var center_screen_uv = (rect_global_position + local_point) / get_viewport().size
*/
uniform vec2 center_screen_uv = vec2(0.5, 0.5);

varying vec4 modulate;

void vertex() {
    modulate = COLOR;
}

void fragment() {
    // Base color (ColorRect or texture)
    vec4 base = texture(TEXTURE, UV) * modulate;

    // Convert screen-UV delta to pixel-space for isotropic distance:
    // SCREEN_PIXEL_SIZE = 1.0 / viewport_size
    vec2 delta_px = (SCREEN_UV - center_screen_uv) / SCREEN_PIXEL_SIZE;
    float dist_px = length(delta_px);

    // A "very large" starting radius that covers the whole screen regardless of center.
    // Using the screen diagonal in pixels.
    float screen_diag_px = length(vec2(1.0) / SCREEN_PIXEL_SIZE);

    // Shrink radius linearly with progress: 0 -> big; 1 -> 0
    float radius_px = mix(screen_diag_px, 0.0, clamp(progress, 0.0, 1.0));

    // Hard-edge mask (no feathering)
    float inside = dist_px <= radius_px ? 1.0 : 0.0;
    float mask = invert ? 1.0 - inside : inside;

    // Apply alpha
    float out_a = use_sprite_alpha ? min(base.a, mask) : mask;

    COLOR = vec4(base.rgb, out_a);
}