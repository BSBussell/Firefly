shader_type canvas_item;

uniform sampler2D normal_map : hint_normal;
uniform sampler2D spec_map;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_nearest;

// If your teardrop has real transparency, leave this true; if it's white-on-black, set to true and we’ll use luma.
uniform bool  use_luma_mask = false;      // true if your sprite is opaque (white-on-black)
uniform float luma_threshold : hint_range(0.0,1.0) = 0.2;
uniform float mask_softness  : hint_range(0.0,0.3) = 0.06;

// Normal/spec
uniform float normal_strength : hint_range(0.0, 4.0) = 1.0;
uniform float spec_intensity  : hint_range(0.0, 4.0) = 1.8;
uniform float min_roughness   : hint_range(0.0, 1.0) = 0.04;
uniform float max_roughness   : hint_range(0.0, 1.0) = 0.30;

// Wet optics
uniform float refract_strength : hint_range(0.0, 0.06) = 0.024;
uniform float reflect_mix      : hint_range(0.0, 1.0) = 0.50;

// Flow/squish animation (subtle)
uniform float drip_speed   : hint_range(0.0, 8.0) = 1.2;   // oscillation speed
uniform float drip_amount  : hint_range(0.0, 0.5) = 0.08;  // vertical UV wobble
uniform float squish_amount: hint_range(0.0, 0.4) = 0.12;  // scale wobble
uniform float flow_scale   : hint_range(0.5, 8.0) = 3.0;   // noise read scale for smear
uniform float flow_amount  : hint_range(0.0, 1.0) = 0.12;  // UV smear intensity

// Dew highlight bias
uniform vec2  gravity_dir = vec2(0.0, 1.0);  // down-screen
uniform float rim_boost   : hint_range(0.0, 2.0) = 0.7;

// Where the “tip zone” starts (in UV.y, 0=top, 1=bottom)
uniform float tip_start_y : hint_range(0.0,1.0) = 0.6;

uniform vec4  albedo_tint = vec4(1.0);

vec3 decode_normal(vec3 n_rgb) {
    vec3 n = n_rgb * 2.0 - 1.0;
    n.xy *= normal_strength;
    return normalize(n);
}

void fragment() {
    vec4 base = texture(TEXTURE, UV) * albedo_tint;
    COLOR = base; // lighting will be added in light()
}

void light() {
    // --- Base color (for light accumulation) ---
    vec4 base_px = texture(TEXTURE, UV) * albedo_tint;

    // --- “Mask” derived from the sprite itself (no extra texture) ---
    float in_shape;
    if (use_luma_mask) {
        // White-on-black: isolate bright shape
        float luma = dot(base_px.rgb, vec3(0.299, 0.587, 0.114));
        in_shape = smoothstep(luma_threshold, luma_threshold + mask_softness, luma);
    } else {
        // Transparent background: use alpha
        in_shape = smoothstep(0.0, mask_softness, base_px.a);
    }

    // --- Tip weighting (stronger near bottom of the sprite) ---
    float tip_w = smoothstep(tip_start_y, 1.0, UV.y); // 0..1 toward bottom

    // --- Tiny drip animation (vertical wobble + squish), strongest near tip ---
    float t = TIME * drip_speed;
    float wob = sin(t + UV.x * 6.28318) * 0.5 + 0.5;
    float tip_amp = mix(0.3, 1.0, tip_w) * in_shape;

    // Vertical wobble
    vec2 wobble_uv = UV;
    wobble_uv.y += (wob - 0.5) * drip_amount * tip_amp;

    // Squish (scale about center) – only near the tip so it feels like stretching
    float s = 1.0 + (wob - 0.5) * squish_amount * tip_amp;
    vec2 center = vec2(0.5, 0.5);
    vec2 squish_uv = (wobble_uv - center) * vec2(1.0, s) + center;

    // --- Subtle UV smear using normal-map-as-noise (keeps a liquid feel) ---
    vec3 flow_n  = texture(normal_map, squish_uv * flow_scale).rgb;
    float wobble_noise = (flow_n.r + flow_n.g) * 0.5;
    vec2 smear = flow_amount * (wobble_noise - 0.5) * vec2(0.0, 1.0) * tip_amp; // smear downwards
    vec2 wet_uv = squish_uv + smear;

    // --- Normal/spec off animated UV ---
    vec3 N = decode_normal(texture(normal_map, wet_uv).rgb);
    vec2 spec_rg = texture(spec_map, wet_uv).rg;
    float spec_strength = spec_rg.r;
    float rough = clamp(mix(min_roughness, max_roughness, spec_rg.g), 0.0001, 1.0);

    // --- Light vectors ---
    vec3 L = normalize(vec3(LIGHT_DIRECTION.x, LIGHT_DIRECTION.y, 1.0));
    vec3 V = vec3(0.0, 0.0, 1.0);
    vec3 H = normalize(L + V);

    float NdotL = max(dot(N, L), 0.0);
    float shininess = clamp(mix(16.0, 256.0, 1.0 - rough), 1.0, 256.0);
    float NdotH = max(dot(N, H), 0.0);
    float spec = pow(NdotH, shininess) * spec_intensity * spec_strength;

    // Bias spec toward the “bottom rim” so you get that crescent glint
    float rim = max(0.0, dot(N, normalize(vec3(gravity_dir, 0.0))));
    spec *= (1.0 + rim_boost * rim * tip_w * in_shape);

    // --- Screen refraction/“reflection” – stronger near tip ---
    float refract_scale = refract_strength * (0.3 + 0.7 * tip_w) * in_shape;
    vec2 screen_uv = SCREEN_UV + N.xy * refract_scale;
    vec3 screen_col = texture(SCREEN_TEXTURE, screen_uv).rgb;

    // --- Diffuse + reflection mix confined to droplet area ---
    vec3 diffuse = base_px.rgb * NdotL * LIGHT_COLOR.rgb;
    vec3 mixed   = mix(diffuse, screen_col, vec3(reflect_mix * in_shape * (0.2 + 0.8 * tip_w)));

    // --- Final with specular ---
    vec3 final_rgb = mixed + LIGHT_COLOR.rgb * spec;

    LIGHT = vec4(final_rgb, base_px.a);
}