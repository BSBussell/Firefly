shader_type canvas_item;


uniform vec2 SIZE = vec2(0.4, 0.2);
uniform float RADIUS : hint_range(0.0, 0.5) = 0.1;
uniform float waveFrequency : hint_range(0.0, 50.0) = 10.0;
uniform float waveAmplitude : hint_range(0.0, 0.5) = 0.02;
uniform float waveSpeed : hint_range(0.0, 10.0) = 2.0;
uniform bool hard_edges = true;

// Randomness
uniform float seed = 0.0; // Different per-instance

// Random function
float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

float rounded_rect_sdf(vec2 uv, vec2 size, float radius) {
    vec2 d = abs(uv - vec2(0.5)) - size + vec2(radius);
    return length(max(d, 0.0)) - radius;
}

float wave_distortion(vec2 uv, float frequency, float amplitude, float speed, float randomness) {
    return sin(uv.y * frequency + TIME * speed + randomness) * amplitude;
}

void fragment() {
    vec2 uv = UV;
    
    float randomness = seed;
    
    float sdf = rounded_rect_sdf(uv, SIZE, RADIUS);
    sdf += wave_distortion(uv, waveFrequency, waveAmplitude, waveSpeed, randomness);
    
    float fill = hard_edges ? step(0.0, -sdf) : smoothstep(0.0, 0.01, -sdf);
    
    COLOR.a *= fill;
}