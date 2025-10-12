shader_type canvas_item;
render_mode unshaded;

// No texture uniform needed - uses SCREEN_TEXTURE for SubViewport
// === Master Toggle ===
uniform bool grading_enable = true;


// === White Balance ===
uniform bool wb_enable = true;
uniform float wb_temperature_K : hint_range(2000.0, 12000.0, 10.0) = 6500.0;
uniform float wb_tint : hint_range(-0.05, 0.05, 0.001) = 0.0;

// === Tone Controls ===
uniform float exposure : hint_range(-4.0, 4.0, 0.01) = 0.0;
uniform float contrast : hint_range(-1.0, 1.0, 0.01) = 0.0;
uniform float highlights : hint_range(-1.0, 1.0, 0.01) = 0.0;
uniform float shadows : hint_range(-1.0, 1.0, 0.01) = 0.0;
uniform float whites : hint_range(-3.2, 3.2, 0.001) = 0.0;
uniform float blacks : hint_range(-3.2, 3.2, 0.001) = 0.0;
uniform float saturation : hint_range(0.0, 2.0, 0.01) = 1.0;

// === Constants ===
const vec3 LUMA = vec3(0.2126, 0.7152, 0.0722);
const vec2 D65_xy = vec2(0.31271, 0.32902);

const mat3 SRGB_TO_XYZ = mat3(
    vec3(0.4124564, 0.3575761, 0.1804375),
    vec3(0.2126729, 0.7151522, 0.0721750),
    vec3(0.0193339, 0.1191920, 0.9503041)
);

const mat3 XYZ_TO_SRGB = mat3(
    vec3( 3.2404542, -1.5371385, -0.4985314),
    vec3(-0.9692660,  1.8760108,  0.0415560),
    vec3( 0.0556434, -0.2040259,  1.0572252)
);

const mat3 BRADFORD = mat3(
    vec3( 0.8951,  0.2664, -0.1614),
    vec3(-0.7502,  1.7135,  0.0367),
    vec3( 0.0389, -0.0685,  1.0296)
);

const mat3 BRADFORD_INV = mat3(
    vec3( 0.9869929, -0.1470543,  0.1599627),
    vec3( 0.4323053,  0.5183603,  0.0492912),
    vec3(-0.0085287,  0.0400428,  0.9684867)
);

// === Helper Functions ===
vec2 cct_to_xy(float K) {
    float t = 1.0 / K;
    float x;
    if (K < 4000.0) {
        x = -0.2661239 * t*t*t - 0.2343580 * t*t + 0.8776956 * t + 0.179910;
    } else {
        x = -3.0258469 * t*t*t + 2.1070379 * t*t + 0.2226347 * t + 0.240390;
    }
    
    float y;
    if (K < 2222.0) {
        y = -1.1063814 * x*x*x - 1.34811020 * x*x + 2.18555832 * x - 0.20219683;
    } else if (K < 4000.0) {
        y = -0.9549476 * x*x*x - 1.37418593 * x*x + 2.09137015 * x - 0.16748867;
    } else {
        y = 3.0817580 * x*x*x - 5.87338670 * x*x + 3.75112997 * x - 0.37001483;
    }
    
    return vec2(x, y);
}

vec3 xy_to_XYZ(vec2 xy) {
    float denom = max(xy.y, 1e-6);
    return vec3(xy.x / denom, 1.0, (1.0 - xy.x - xy.y) / denom);
}

vec2 xy_to_upvp(vec2 xy) {
    float denom = -2.0 * xy.x + 12.0 * xy.y + 3.0;
    return vec2(4.0 * xy.x / denom, 9.0 * xy.y / denom);
}

vec2 upvp_to_xy(vec2 upvp) {
    float denom = 6.0 * upvp.x - 16.0 * upvp.y + 12.0;
    return vec2(9.0 * upvp.x / denom, 4.0 * upvp.y / denom);
}

mat3 cat_bradford(vec3 srcW, vec3 dstW) {
    vec3 srcLMS = BRADFORD * srcW;
    vec3 dstLMS = BRADFORD * dstW;
    
    mat3 D = mat3(
        vec3(dstLMS.x / max(srcLMS.x, 1e-6), 0.0, 0.0),
        vec3(0.0, dstLMS.y / max(srcLMS.y, 1e-6), 0.0),
        vec3(0.0, 0.0, dstLMS.z / max(srcLMS.z, 1e-6))
    );
    
    return BRADFORD_INV * D * BRADFORD;
}

// Build per-channel white-balance gains from Kelvin + tint
// Direction: D65 -> target (pushes the image toward the selected white)
vec3 make_wb_gains(float temp_K, float tint_uv) {
    // Base white from Kelvin
    vec2 xy = cct_to_xy(temp_K);
    
    // Apply tint as small u' offset (green<->magenta)
    vec2 upvp = xy_to_upvp(xy);
    upvp.x += tint_uv;
    vec2 xy_tinted = upvp_to_xy(upvp);
    
    // Chromatic adaptation D65 -> target
    vec3 W_d65 = xy_to_XYZ(D65_xy);
    vec3 W_target = xy_to_XYZ(xy_tinted);
    mat3 CAT = cat_bradford(W_d65, W_target);
    
    // Fold through RGB<->XYZ to see how white moves in RGB
    mat3 M = XYZ_TO_SRGB * CAT * SRGB_TO_XYZ;
    
    // Apply to neutral to get per-channel white shift
    vec3 white_rgb = M * vec3(1.0);
    
    // Normalize gains so green ~ 1 (stable mid pivot)
    float g_norm = max(white_rgb.g, 1e-6);
    vec3 gains = white_rgb / g_norm;
    
    // Prevent extreme values
    gains = clamp(gains, vec3(0.2), vec3(5.0));
    return gains;
}

// === Tone Functions ===
float soft_knee(float x, float knee) {
    float a = knee * 0.5;
    return x / (1.0 + a * abs(x - 0.5) * 2.0);
}

vec3 apply_contrast(vec3 c, float amount) {
    if (amount == 0.0) return c;
    
    const float pivot = 0.18;
    float k = abs(amount);
    vec3 result = pivot + (c - pivot) * (1.0 + amount * 1.6);
    
    return clamp(vec3(
        soft_knee(result.r, k),
        soft_knee(result.g, k),
        soft_knee(result.b, k)
    ), 0.0, 1.0);
}

float mask_highlights_rgb(vec3 c) {
    float m = max(max(c.r, c.g), c.b);
    return smoothstep(0.50, 0.80, m);
}

float mask_shadows(float Y) { return 1.0 - smoothstep(0.20, 0.40, Y); }

vec3 adjust_highlights(vec3 c, float amt) {
    if (amt >= 0.0) {
        // Compress
        return mix(c, 1.0 - pow(1.0 - c, vec3(1.0 + 4.0 * amt)), amt);
    } else {
        // Expand
        float s = -amt;
        return mix(c, pow(c, vec3(1.0 + 2.0 * s)), s);
    }
}

vec3 adjust_shadows(vec3 c, float amt) {
    if (amt >= 0.0) {
        // Lift
        vec3 lift = c + (vec3(1.0) - exp(-4.0 * c)) * (0.25 * amt);
        lift = pow(lift, vec3(1.0 / (1.0 + 0.6 * amt)));
        return mix(c, lift, amt);
    } else {
        // Deepen
        float s = -amt;
        return mix(c, pow(c, vec3(1.0 + 1.5 * s)), s);
    }
}

float remap_endpoints(float x, float b_off, float w_off) {
    // Gentle blacks lift/deepen near 0, gentle whites push/pull near 1.
    // Small offsets feel small; mids stay anchored.

    float y = x;

    // --- Blacks: affect the toe (near 0)
    if (b_off != 0.0) {
        // Mask influence to the dark range so mids don't jump
        float mb = 1.0 - smoothstep(0.20, 0.40, y);
        // Nonlinear lift/deepen with an exponential toe so it feels photographic
        float lift = y + (1.0 - exp(-6.0 * y)) * (b_off * 0.8);
        y = mix(y, lift, mb);
    }

    // --- Whites: affect the shoulder (near 1)
    if (w_off != 0.0) {
        float mw = smoothstep(0.60, 0.85, y);
        float inv = 1.0 - y;
        // Nonlinear shoulder shaping in “inv” space
        float push = inv + (1.0 - exp(-6.0 * inv)) * (w_off * 0.8);
        y = mix(y, 1.0 - push, mw);
    }

    return clamp(y, 0.0, 1.0);
}

// === Main Fragment ===
void fragment() {
	
	// If toggle is off, just pass through
    if (grading_enable) {
       
       
    
	
    vec4 texel = texture(TEXTURE, UV);
    vec3 c = texel.rgb;
    
    // White Balance (gain-based)
    if (wb_enable) {
        // Scale tint down for more subtle control
        vec3 wb_gains = make_wb_gains(wb_temperature_K, wb_tint * 0.5);
        c *= wb_gains;
        c = max(c, vec3(0.0));
    }
    
    // Exposure
    c *= exp2(exposure);
    
    // Contrast
    c = apply_contrast(c, contrast);
    
    // Highlights & Shadows
    if (highlights != 0.0 || shadows != 0.0) {
        float Y = dot(c, LUMA);
        
        if (highlights != 0.0) {
            float mH = mask_highlights_rgb(c);
            c = mix(c, adjust_highlights(c, highlights), mH);
        }
        
        if (shadows != 0.0) {
            float mS = mask_shadows(Y);
            c = mix(c, adjust_shadows(c, shadows), mS);
        }
    }
    
    // Whites & Blacks
    if (whites != 0.0 || blacks != 0.0) {
        c = vec3(
            remap_endpoints(c.r, blacks, whites),
            remap_endpoints(c.g, blacks, whites),
            remap_endpoints(c.b, blacks, whites)
        );
    }
    
    // Saturation
    if (saturation != 1.0) {
        float Y = dot(c, LUMA);
        c = mix(vec3(Y), c, saturation);
    }
    
    COLOR = vec4(clamp(c, 0.0, 1.0), texel.a);
	}
}
