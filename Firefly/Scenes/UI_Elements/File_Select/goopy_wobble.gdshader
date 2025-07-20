shader_type canvas_item;

uniform vec2 SIZE = vec2(0.4, 0.2);
uniform float RADIUS : hint_range(0.0, 0.5) = 0.1;

uniform float waveFrequency : hint_range(0.0, 50.0) = 10.0;
uniform float waveAmplitude : hint_range(0.0, 0.5) = 0.02;
uniform float waveSpeed : hint_range(0.0, 10.0) = 2.0;

uniform bool hard_edges = true;
uniform float seed = 0.0;

/// Blend: 0 = structured sine wobble, 1 = goopy chaos
uniform float goopyness : hint_range(0.0, 1.0) = 1.0;

/// How much either type of distortion affects the shape
uniform float distortion_strength : hint_range(0.0, 1.0) = 1.0;


// --- Noise helpers
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float noise(vec2 p, float seed_offset) {
    vec2 i = floor(p);
    vec2 f = fract(p);

    float a = hash(i + vec2(0.0, 0.0) + seed_offset);
    float b = hash(i + vec2(1.0, 0.0) + seed_offset);
    float c = hash(i + vec2(0.0, 1.0) + seed_offset);
    float d = hash(i + vec2(1.0, 1.0) + seed_offset);

    vec2 u = f * f * (3.0 - 2.0 * f);

    return mix(a, b, u.x) +
           (c - a) * u.y * (1.0 - u.x) +
           (d - b) * u.x * u.y;
}

// --- Shape
float rounded_rect_sdf(vec2 uv, vec2 size, float radius) {
    vec2 d = abs(uv - vec2(0.5)) - size + vec2(radius);
    return length(max(d, 0.0)) - radius;
}

// --- Wobble mix function
float blended_distortion(vec2 uv, float frequency, float amplitude, float speed, float seed_offset) {
    float sine_wobble = sin(uv.y * frequency + TIME * speed + seed_offset);
    
    vec2 noise_input = uv * frequency + vec2(TIME * speed, 0.0);
    float noise_val = noise(noise_input, seed_offset);
    float goopy_wobble = (noise_val - 0.5) * 2.0;

    float blended = mix(sine_wobble, goopy_wobble, goopyness);
    return blended * amplitude * distortion_strength;
}

void fragment() {
    vec2 uv = UV;

    float sdf = rounded_rect_sdf(uv, SIZE, RADIUS);
    sdf += blended_distortion(uv, waveFrequency, waveAmplitude, waveSpeed, seed);

    float fill = hard_edges
        ? step(0.0, -sdf)
        : smoothstep(0.0, 0.01, -sdf);

    COLOR.a *= fill;
}