shader_type canvas_item;

/* ---------- Inputs ---------- */
uniform sampler2D normal_map : hint_normal;
uniform sampler2D spec_map;

/* Opaque (white-on-black) vs. true alpha sprites */
uniform bool  use_luma_mask = false;
uniform float luma_threshold : hint_range(0.0,1.0) = 0.20;
uniform float mask_softness  : hint_range(0.0,0.3) = 0.06;

/* Pixel-art nicety */
uniform bool  snap_texels = true;

/* Base tint */
uniform vec4  albedo_tint = vec4(1.0);

/* ---------- Normal / Spec controls ---------- */
uniform float normal_strength : hint_range(0.0, 4.0) = 1.0;
uniform float spec_intensity  : hint_range(0.0, 4.0) = 1.2;
uniform float min_roughness   : hint_range(0.0, 1.0) = 0.06;
uniform float max_roughness   : hint_range(0.0, 1.0) = 0.30;

/* ---------- Sparkle (A + F + E) ---------- */
uniform float band1_density : hint_range(0.0, 0.20) = 0.030; // subtle bed
uniform float band2_density : hint_range(0.0, 0.05) = 0.006; // rare pops
uniform float band1_speed   : hint_range(0.0, 10.0) = 1.7;
uniform float band2_speed   : hint_range(0.0, 10.0) = 2.9;
uniform float band1_sharp   : hint_range(1.0, 16.0) = 6.0;
uniform float band2_sharp   : hint_range(1.0, 32.0) = 12.0;

uniform float anisotropy_strength : hint_range(0.0, 2.0) = 0.7;
uniform float sparkle_intensity   : hint_range(0.0, 2.0) = 0.9;

/* Optional tint for the sparkle (set A=0 for none) */
uniform vec4  sparkle_color : source_color = vec4(1.0, 1.0, 1.0, 0.15);

/* Selection stability */
uniform float sparkle_block_texels : hint_range(1.0, 4.0) = 1.0;
uniform float seed = 0.0;

/* Alpha cut for true-alpha sprites */
uniform float alpha_threshold : hint_range(0.0,1.0) = 0.01;

/* ---------- Helpers ---------- */
float hash21(vec2 p){
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 34.345);
    return fract(p.x * p.y);
}

vec3 decode_normal(vec3 n_rgb){
    vec3 n = n_rgb * 2.0 - 1.0;
    n.xy *= normal_strength;
    return normalize(n);
}

vec3 rgb2hsv(vec3 c){
    float cmax = max(c.r, max(c.g, c.b));
    float cmin = min(c.r, min(c.g, c.b));
    float d = cmax - cmin;
    float h = 0.0;
    if (d > 1e-5){
        if (cmax == c.r)      h = mod((c.g - c.b) / d, 6.0);
        else if (cmax == c.g) h = (c.b - c.r) / d + 2.0;
        else                  h = (c.r - c.g) / d + 4.0;
        h /= 6.0;
    }
    float s = (cmax <= 0.0) ? 0.0 : d / cmax;
    return vec3(h, s, cmax);
}

vec3 hsv2rgb(vec3 c){
    float h = c.x * 6.0;
    float s = c.y;
    float v = c.z;
    float i = floor(h);
    float f = h - i;
    float p = v * (1.0 - s);
    float q = v * (1.0 - s * f);
    float t = v * (1.0 - s * (1.0 - f));
    vec3 outc;
    if      (i == 0.0) outc = vec3(v, t, p);
    else if (i == 1.0) outc = vec3(q, v, p);
    else if (i == 2.0) outc = vec3(p, v, t);
    else if (i == 3.0) outc = vec3(p, q, v);
    else if (i == 4.0) outc = vec3(t, p, v);
    else               outc = vec3(v, p, q);
    return outc;
}

/* ---------- Fragment: Complete shader logic here ---------- */
void fragment(){
    vec2 uv = UV;
    if (snap_texels){
        vec2 texel = TEXTURE_PIXEL_SIZE;
        uv = (floor(UV / texel) + 0.5) * texel;
    }
    
    vec4 base_px = texture(TEXTURE, uv) * albedo_tint;
    
    // Handle transparency without early return
    if (base_px.a >= alpha_threshold) {
        // Mask calculation
        float in_shape;
        if (use_luma_mask){
            float luma = dot(base_px.rgb, vec3(0.299, 0.587, 0.114));
            in_shape = smoothstep(luma_threshold, luma_threshold + mask_softness, luma);
        } else {
            in_shape = smoothstep(alpha_threshold, alpha_threshold + mask_softness, base_px.a);
        }

        // Fake lighting direction (simulates light from top-right)
        vec3 light_dir = normalize(vec3(0.5, -0.7, 1.0));
        
        // Normal from normal map or default
        vec3 N = vec3(0.0, 0.0, 1.0);
        if (textureSize(normal_map, 0).x > 1) {
            N = decode_normal(texture(normal_map, uv).rgb);
        }
        
        // Spec data from spec map or defaults
        vec2 spec_rg = vec2(1.0, 0.5);
        if (textureSize(spec_map, 0).x > 1) {
            spec_rg = texture(spec_map, uv).rg;
        }
        float spec_strength = spec_rg.r;
        float rough = clamp(mix(min_roughness, max_roughness, spec_rg.g), 0.0001, 1.0);

        // Basic lighting calculation
        float NdotL = max(dot(N, light_dir), 0.0);
        vec3 H = normalize(light_dir + vec3(0.0, 0.0, 1.0));
        float shininess = clamp(mix(16.0, 256.0, 1.0 - rough), 1.0, 256.0);
        float spec_term = pow(max(dot(N, H), 0.0), shininess) * spec_intensity * spec_strength;
        
        // Highlight gate - controls where sparkles can appear
        float highlight = clamp(NdotL * 0.8 + spec_term + 0.3, 0.0, 1.0) * in_shape;

        // --- Sparkle System ---
        float block = max(1.0, round(sparkle_block_texels));
        vec2 texel = max(vec2(1e-6), TEXTURE_PIXEL_SIZE);
        vec2 ixy = floor(uv / texel);
        vec2 bcoord = floor(ixy / block);

        // Random selection for each sparkle band
        float pick1  = hash21(bcoord + vec2(seed + 13.1, seed * 1.37));
        float pick2  = hash21(bcoord + vec2(seed * 2.71, seed + 47.3));
        float phase1 = hash21(bcoord + vec2(17.0 + seed, 29.0 - seed));
        float phase2 = hash21(bcoord + vec2(41.0 - seed, 73.0 + seed));

        // Sparkle selection based on density and highlight
        float chosen1 = step(1.0 - band1_density * highlight, pick1);
        float chosen2 = step(1.0 - band2_density * highlight, pick2);

        // Animated sparkle intensity
        float s1 = 0.5 + 0.5 * sin((TIME * band1_speed + phase1) * 6.2831853);
        float s2 = 0.5 + 0.5 * sin((TIME * band2_speed + phase2) * 6.2831853);

        float twinkle1 = pow(s1, band1_sharp);
        float twinkle2 = pow(s2, band2_sharp);

        // Anisotropy - sparkles favor light alignment
        vec2 nxy = normalize(N.xy + 1e-5);
        vec2 lxy = normalize(light_dir.xy + 1e-5);
        float align = abs(dot(nxy, lxy));
        float aniso = mix(1.0, align, anisotropy_strength);

        // Calculate final sparkle value
        float sparkle_v = (chosen1 * twinkle1 * 0.6 + chosen2 * twinkle2 * 1.2) * highlight * aniso * sparkle_intensity;

        // Apply sparkle as HSV brightness boost to preserve hue
        vec3 hsv = rgb2hsv(base_px.rgb);
        hsv.z = clamp(hsv.z + sparkle_v, 0.0, 1.0);
        vec3 result_rgb = hsv2rgb(hsv);

        // Optional sparkle color tinting
        if (sparkle_color.a > 0.0){
            vec3 tinted = result_rgb + sparkle_color.rgb * sparkle_v;
            result_rgb = mix(result_rgb, clamp(tinted, 0.0, 1.0), sparkle_color.a);
        }

        // Apply basic lighting to the result
        float lighting = mix(0.7, 1.3, NdotL * in_shape);
        result_rgb *= lighting;
        
        // Add specular highlights
        result_rgb += spec_term * in_shape;

        COLOR = vec4(result_rgb, base_px.a);
    } else {
        // Transparent pixel
        COLOR = vec4(0.0, 0.0, 0.0, 0.0);
    }
}