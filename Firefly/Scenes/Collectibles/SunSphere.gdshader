shader_type canvas_item;

uniform sampler2D normal_map : hint_normal;
uniform sampler2D spec_map;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_nearest;

// Masking
uniform bool  use_luma_mask = false;
uniform float luma_threshold : hint_range(0.0,1.0) = 0.20;
uniform float mask_softness  : hint_range(0.0,0.3)  = 0.06;

// Normal/spec controls
uniform float normal_strength : hint_range(0.0, 4.0) = 1.0;
uniform float spec_intensity  : hint_range(0.0, 4.0) = 1.2;
uniform float min_roughness   : hint_range(0.0, 1.0) = 0.06;
uniform float max_roughness   : hint_range(0.0, 1.0) = 0.35;

// Spin & tiles
uniform float spin_speed   : hint_range(-6.0, 6.0) = 0.75;
uniform float tile_scale   : hint_range(0.25, 8.0) = 1.0;
uniform float spin_parallax: hint_range(0.0, 2.0)  = 0.9;

// Glint band
uniform float sweep_speed  : hint_range(0.0, 10.0) = 1.0;
uniform float band_width   : hint_range(0.01, 1.0) = 0.30;
uniform float band_strength: hint_range(0.0, 3.0)  = 0.9;

// Sparkles
uniform float sparkle_speed   : hint_range(0.0, 10.0) = 1.5;
uniform float sparkle_density : hint_range(2.0, 80.0) = 24.0;
uniform float sparkle_amount  : hint_range(0.0, 2.0)  = 0.25;
uniform float sparkle_thresh  : hint_range(0.80, 0.99) = 0.95;

// Screen refraction/“reflection”
uniform float refract_strength : hint_range(0.0, 0.06) = 0.0; 
uniform float reflect_mix      : hint_range(0.0, 1.0)  = 0.35;

// Pixel-art safety
uniform bool  pixel_snap         = true;
uniform float pixel_fps          : hint_range(1.0, 60.0) = 8.0;
uniform int   texel_step_x       = 1;
uniform int   texel_step_y       = 0;
uniform bool  snap_refraction    = true;
uniform bool  hard_edges_band    = true;

// This is your manual “screen pixel size” (usually 1.0 / virtual_resolution)
uniform vec2  pixel_size = vec2(0.03, 0.02);

uniform vec4  albedo_tint = vec4(1.0);

// ── helpers ─────────────────────────────────────────────────────────────
vec3 decode_normal(vec3 n_rgb) {
    vec3 n = n_rgb * 2.0 - 1.0;
    n.xy *= normal_strength;
    return normalize(n);
}

vec2 rot(vec2 p, float a) {
    float c = cos(a), s = sin(a);
    return vec2(c*p.x - s*p.y, s*p.x + c*p.y);
}

float hash21(vec2 p){
    p = fract(p * vec2(123.34, 345.45));
    p += dot(p, p + 34.345);
    return fract(p.x * p.y);
}

float noise2(vec2 p){
    vec2 i = floor(p);
    vec2 f = fract(p);
    float a = hash21(i);
    float b = hash21(i + vec2(1.0, 0.0));
    float c = hash21(i + vec2(0.0, 1.0));
    float d = hash21(i + vec2(1.0, 1.0));
    vec2 u = f*f*(3.0 - 2.0*f);
    return mix(mix(a,b,u.x), mix(c,d,u.x), u.y);
}

float sphere_z(vec2 uv) {
    vec2 p = uv * 2.0 - 1.0;
    float r2 = dot(p, p);
    return (r2 >= 1.0) ? 0.0 : sqrt(max(0.0, 1.0 - r2));
}

// Quantize helpers
float quantize_time(float t) {
    if (!pixel_snap) return t;
    float step_t = 1.0 / max(1.0, pixel_fps);
    return floor(t / step_t) * step_t;
}

vec2 snap_uv_to_pixel(vec2 uv, vec2 pix) {
    if (!pixel_snap) return uv;
    return floor(uv / pix + 0.5) * pix;
}

// ── shader stages ───────────────────────────────────────────────────────
void fragment() {
    vec4 base = texture(TEXTURE, UV) * albedo_tint;
    COLOR = base;
}

void light() {
    vec4 base_px = texture(TEXTURE, UV) * albedo_tint;

    float in_shape;
    if (use_luma_mask) {
        float luma = dot(base_px.rgb, vec3(0.299, 0.587, 0.114));
        in_shape = smoothstep(luma_threshold, luma_threshold + mask_softness, luma);
    } else {
        in_shape = smoothstep(0.0, mask_softness, base_px.a);
    }

    float t = quantize_time(TIME);

    // Spinning UVs
    float z = sphere_z(UV);
    float par = mix(1.0, z, spin_parallax);

    float shift_texels_x = 0.0;
    {
        float shift_cont = t * spin_speed * par;
        float shift_px   = shift_cont / TEXTURE_PIXEL_SIZE.x;
        float step_px    = float(max(1, texel_step_x));
        float snapped_px = pixel_snap ? floor(shift_px / step_px) * step_px : shift_px;
        shift_texels_x   = snapped_px;
    }

    vec2 uv_centered = UV - 0.5;
    vec2 spun = rot(uv_centered, t*0.15) + 0.5;

    vec2 spin_uv = spun * tile_scale + vec2(shift_texels_x * TEXTURE_PIXEL_SIZE.x, float(texel_step_y) * TEXTURE_PIXEL_SIZE.y);
    spin_uv = fract(spin_uv);

    // Sample normal/spec
    vec3 N = decode_normal(texture(normal_map, spin_uv).rgb);
    vec2 spec_rg = texture(spec_map, spin_uv).rg;
    float spec_strength = spec_rg.r;
    float rough = clamp(mix(min_roughness, max_roughness, spec_rg.g), 0.0001, 1.0);

    // Lighting vectors
    vec3 L = normalize(vec3(LIGHT_DIRECTION.x, LIGHT_DIRECTION.y, 1.0));
    vec3 V = vec3(0.0, 0.0, 1.0);
    vec3 H = normalize(L + V);

    float NdotL = max(dot(N, L), 0.0);
    float shininess = clamp(mix(24.0, 256.0, 1.0 - rough), 1.0, 256.0);
    float NdotH = max(dot(N, H), 0.0);
    float spec = pow(NdotH, shininess) * spec_intensity * spec_strength;

    // Glint band
    vec2 p = uv_centered * 2.0;
    float ang = t * sweep_speed;
    vec2 pr = rot(p, ang);
    float dist_to_line = abs(pr.x);

    float band;
    if (hard_edges_band) {
        float quant = TEXTURE_PIXEL_SIZE.x * 2.0;
        float d_q = floor(dist_to_line / quant + 0.5) * quant;
        band = float(d_q < band_width) * band_strength * spec_strength;
    } else {
        band = smoothstep(band_width, 0.0, dist_to_line) * band_strength * spec_strength;
    }

    // Sparkles
    float sparkle_t = pixel_snap ? floor(t * sparkle_speed * pixel_fps) / max(1.0, pixel_fps)
                                 : t * sparkle_speed;
    vec2 cell_uv = floor(spin_uv / TEXTURE_PIXEL_SIZE) * TEXTURE_PIXEL_SIZE;
    float tw = noise2(cell_uv * sparkle_density + sparkle_t);
    float spark_mask = step(sparkle_thresh, tw) * (0.3 + 0.7 * NdotL);
    float sparkles = spark_mask * sparkle_amount * spec_strength;

    // Screen refraction/“reflection”
    float refract_scale = refract_strength * in_shape * (0.4 + 0.6 * z);
    vec2 screen_uv = SCREEN_UV + N.xy * refract_scale;
    if (snap_refraction && pixel_snap) {
        screen_uv = snap_uv_to_pixel(screen_uv, pixel_size);
    }
    screen_uv = clamp(screen_uv, vec2(0.0), vec2(1.0));
    vec3 screen_col = texture(SCREEN_TEXTURE, screen_uv).rgb;

    vec3 diffuse = base_px.rgb * NdotL * LIGHT_COLOR.rgb;
    vec3 reflected = mix(diffuse, screen_col, vec3(reflect_mix * in_shape));

    vec3 highlights = (spec + band + sparkles) * LIGHT_COLOR.rgb;
    vec3 final_rgb = mix(vec3(0.0), reflected + highlights, in_shape);

    LIGHT = vec4(final_rgb, base_px.a * in_shape);
}