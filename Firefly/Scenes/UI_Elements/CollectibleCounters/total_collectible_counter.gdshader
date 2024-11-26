shader_type canvas_item;

// Parameters for rounded rectangle
uniform vec2 SIZE = vec2(0.4, 0.2); // Size of the rectangle
uniform float RADIUS : hint_range(0.0, 0.5) = 0.1;         // Corner radius

// Parameters for wave distortion
uniform float waveFrequency : hint_range(0.0, 50.0) = 10.0; // Wave frequency
uniform float waveAmplitude : hint_range(0.0, 0.5) = 0.02;  // Wave amplitude
uniform float waveSpeed : hint_range(0.0, 10.0) = 2.0;      // Wave speed

// Hard edges or smooth edges
uniform bool hard_edges = true; // If true, edges are sharp (on/off)

// Rounded rectangle SDF
float rounded_rect_sdf(vec2 uv, vec2 size, float radius) {
    vec2 d = abs(uv - vec2(0.5)) - size + vec2(radius);
    return length(max(d, 0.0)) - radius;
}

// Wavy distortion
float wave_distortion(vec2 uv, float frequency, float amplitude, float speed) {
    return sin(uv.y * frequency + TIME * speed) * amplitude;
}

// Fragment shader
void fragment() {
    vec2 uv = UV;
    
    // Calculate the SDF for the rounded rectangle
    float sdf = rounded_rect_sdf(uv, SIZE, RADIUS);
    
    // Apply wave distortion to the SDF
    sdf += wave_distortion(uv, waveFrequency, waveAmplitude, waveSpeed);
    
    // Determine the fill (1 for inside, 0 for outside)
    float fill = hard_edges ? step(0.0, -sdf) : smoothstep(0.0, 0.01, -sdf);
    
    // Blend the original texture color with the fill
    vec4 originalColor = COLOR;
    COLOR = vec4(originalColor.rgb, originalColor.a * fill);
}