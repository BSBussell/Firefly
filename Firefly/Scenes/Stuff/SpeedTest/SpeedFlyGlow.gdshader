shader_type canvas_item;
render_mode unshaded, blend_mix; // mix so alpha is written (works in transparent SubViewport)

// Tint & brightness
uniform vec4 glow_color : source_color = vec4(1.0, 0.95, 0.85, 1.0);
uniform float intensity : hint_range(0.0, 6.0) = 1.6;

// Shape across the width: 0 at edges → 1 at center
uniform float edge_softness : hint_range(0.05, 1.0) = 0.6;
uniform float falloff_power : hint_range(0.5, 8.0) = 2.2;
uniform float core_boost    : hint_range(0.0, 2.0) = 0.35;

// Optional taper along the length (Line2D: Texture Mode = STRETCH)
uniform bool use_taper = false;
uniform sampler2D taper_tex : source_color;

void fragment() {
    // Cache vertex color BEFORE writing to COLOR
    vec4 vcol = COLOR;

    // Line2D UV: y runs edge(0) → center(0.5) → edge(1)
    float d = abs(UV.y - 0.5) * 2.0; // 0 center, 1 edges
    float soft = clamp((1.0 - d) / max(edge_softness, 1e-4), 0.0, 1.0);

    float alpha = pow(soft, falloff_power);
    if (core_boost > 0.0) {
        float center = pow(1.0 - d, 8.0);
        alpha = max(alpha, core_boost * center);
    }

    if (use_taper) {
        float t = clamp(UV.x, 0.0, 1.0);
        alpha *= texture(taper_tex, vec2(t, 0.5)).a;
    }

    // Compose — don’t multiply by vcol.rgb (can be black on Line2D), but keep vcol.a
    vec3 out_rgb = glow_color.rgb * intensity;
    float out_a = glow_color.a * alpha * clamp(vcol.a, 0.0, 1.0);

    COLOR = vec4(out_rgb, out_a);
}