shader_type canvas_item;

/// Fill value
/// Controls the progress of the fill effect.
uniform float progress;

/// Wave Frequency 1
/// Controls the frequency of the first wave.
uniform float waveFrequency1 : hint_range(0.0, 10.0) = 3.0;

/// Wave Frequency 2
/// Controls the frequency of the second wave.
uniform float waveFrequency2 : hint_range(0.0, 10.0) = 5.0;

/// Wave Amplitude 1
/// Controls the amplitude (height) of the first wave.
uniform float waveAmplitude1 : hint_range(0.0, 0.5) = 0.05;

/// Wave Amplitude 2
/// Controls the amplitude (height) of the second wave.
uniform float waveAmplitude2 : hint_range(0.0, 0.5) = 0.02;

/// Wave Speed 1
/// Controls the speed of the first wave.
uniform float waveSpeed1 : hint_range(0.0, 10.0) = 2.0;

/// Wave Speed 2
/// Controls the speed of the second wave.
uniform float waveSpeed2 : hint_range(0.0, 10.0) = 3.0;

/// Wave Length 1
/// Controls the wavelength of the first wave.
uniform float waveLength1 : hint_range(0.1, 10.0) = 1.0;

/// Wave Length 2
/// Controls the wavelength of the second wave.
uniform float waveLength2 : hint_range(0.1, 10.0) = 1.0;

/// Noise Scale
/// Controls the scale of the noise added to the wave effect.
uniform float noiseScale : hint_range(0.0, 10.0) = 1.0;

/// Noise Speed
/// Controls the speed of the noise animation.
uniform float noiseSpeed : hint_range(0.0, 10.0) = 1.0;

float rand(vec2 co) {
    return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

float noise(vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);
    float a = rand(i);
    float b = rand(i + vec2(1.0, 0.0));
    float c = rand(i + vec2(0.0, 1.0));
    float d = rand(i + vec2(1.0, 1.0));
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

void fragment() {
    vec2 uv = UV;

    // Calculate the distance from the center to create a smooth fill effect
    float sdf = abs(uv.x - 0.5) * 2.0;

    // Create a step function to control the fill progress
    float fillProgress = smoothstep(0.0, 1.0, progress);

    // Use sine waves to create a wavy effect, incorporating wavelength
    float waveOffset1 = (sin((TIME * waveSpeed1 + uv.y / waveLength1) * waveFrequency1) * waveAmplitude1) + waveAmplitude1;
    float waveOffset2 = (cos((TIME * waveSpeed2 + uv.y / waveLength2) * waveFrequency2) * waveAmplitude2) + waveAmplitude2;

    // Add noise to the wave effect
    float noiseValue = noise(uv * noiseScale + vec2(TIME * noiseSpeed));
    float noiseOffset = (noiseValue - 0.5) * 0.1;

    // Calculate the fill threshold including the wave effect
    float threshold = fillProgress + waveOffset1 + waveOffset2 + noiseOffset;

    // Ensure the wave doesn't extend too far below the initial progress
    //threshold = max(threshold, fillProgress);

    // Determine the fill based on the threshold
    float fill = step(sdf, threshold);

    // Get the original color from the texture
    vec4 originalColor = texture(TEXTURE, UV);

    // Set the final color: original color for filled parts, transparent for non-filled parts
    vec4 finalColor = vec4(originalColor.rgb, originalColor.a * fill);

    // Set the final color
    COLOR.a = finalColor.a * COLOR.a;
}
