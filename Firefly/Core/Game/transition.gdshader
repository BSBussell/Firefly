shader_type canvas_item;

// Fill value
uniform float progress;

// Wave parameters
uniform float waveFrequency1 : hint_range(0.0, 10.0) = 2.0;
uniform float waveFrequency2 : hint_range(0.0, 10.0) = 1.5;
uniform float waveAmplitude1 : hint_range(0.0, 1.0) = 0.05;
uniform float waveAmplitude2 : hint_range(0.0, 1.0) = 0.05;
uniform float waveSpeed1 : hint_range(0.0, 10.0) = 2.0;
uniform float waveSpeed2 : hint_range(0.0, 10.0) = 2.0;
uniform float noiseScale : hint_range(0.0, 10.0) = 1.0;
uniform float noiseSpeed : hint_range(0.0, 10.0) = 1.0;

float rand(vec2 co){
    return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

float noise(vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);
    float a = rand(i);
    float b = rand(i + vec2(1.0, 0.0));
    float c = rand(i + vec2(0.0, 1.0));
    float d = rand(i + vec2(1.0, 1.0));
    vec2 u = f*f*(3.0-2.0*f);
    return mix(a, b, u.x) + (c - a)* u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

void fragment() {
    vec2 uv = UV;

    // Calculate the distance from the left edge to create a smooth fill effect
    float sdf = uv.x;

    // Create a step function to control the fill progress
    float fillProgress = smoothstep(0.0, 1.0, progress);

    // Use sine waves to create a wavy effect
    float waveOffset = (sin((TIME * waveSpeed1 + uv.y) * waveFrequency1) * waveAmplitude1) +
                       (sin((TIME * waveSpeed2 + uv.y) * waveFrequency2) * waveAmplitude2);

    // Add noise to the wave effect
    float noiseValue = noise(uv * noiseScale + vec2(TIME * noiseSpeed));
    waveOffset += (noiseValue - 0.5) * 0.1;

    // Calculate the fill threshold including the wave effect
    float threshold = fillProgress + waveOffset;

    // Determine the fill based on the threshold
    float fill = step(sdf, threshold);

    // Get the original color from the texture
    vec4 originalColor = texture(TEXTURE, UV);

    // Set the final color: original color for filled parts, transparent for non-filled parts
    vec4 finalColor = vec4(originalColor.rgb, originalColor.a * fill);

    // Set the final color
    COLOR.a = finalColor.a;
}
