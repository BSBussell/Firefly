shader_type canvas_item;

// Uniforms for controlling the blobs
uniform float time : hint_range(0.0, 100.0) = 0.0;
uniform vec2 resolution;
uniform float speed : hint_range(0.0, 10.0) = 1.0;
uniform float scale : hint_range(0.0, 2.0) = 1.0;

// Blob positions and properties
uniform vec2 blob1_pos = vec2(0.3, 0.5);
uniform vec2 blob2_pos = vec2(0.7, 0.5);
uniform float blob1_radius : hint_range(0.0, 1.0) = 0.3;
uniform float blob2_radius : hint_range(0.0, 1.0) = 0.3;

// Function to create a circular blob
float circle(vec2 uv, vec2 position, float radius) {
    return smoothstep(radius, radius - 0.02, length(uv - position));
}

void fragment() {
    vec2 uv = FRAGCOORD.xy / resolution.xy;
    uv.y = 1.0 - uv.y;  // Invert y-axis to match canvas coordinates

    // Animate blob positions
    vec2 animated_blob1_pos = blob1_pos + vec2(sin(time * speed), cos(time * speed)) * 0.05;
    vec2 animated_blob2_pos = blob2_pos + vec2(cos(time * speed * 1.3), sin(time * speed * 1.3)) * 0.05;

    // Create blobs
    float blob1 = circle(uv, animated_blob1_pos, blob1_radius * scale);
    float blob2 = circle(uv, animated_blob2_pos, blob2_radius * scale);

    // Combine blobs using max (to give a merging effect)
    float blobs = max(blob1, blob2);

    // Create a smooth boundary
    float edge = smoothstep(0.01, 0.02, blobs);

    // Final color
    vec4 color = vec4(0.8, 0.2, 0.2, edge);  // Red color with transparency

    // Output the color
    COLOR = color;
}
