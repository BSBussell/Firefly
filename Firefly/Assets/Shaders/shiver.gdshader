shader_type canvas_item;
render_mode blend_mix;

// Wind settings.
uniform float speed = 1.0;
uniform float minStrength : hint_range(0.0, 1.0) = 0.0;
uniform float maxStrength : hint_range(0.0, 1.0) = 0.04;
uniform float strengthScale = 50.0;
uniform float interval = 5.0;
uniform float distortion : hint_range(0.0, 1.0);
uniform float heightOffset : hint_range(0.0, 1.0);
uniform float offset = 0; // random offset per object

// Random noise function
float rand(vec2 co) {
    return fract(sin(dot(co.xy, vec2(12.9898,78.233))) * 43758.5453);
}

float getWind(vec2 vertex, vec2 uv, float time){
    float diff = pow(maxStrength - minStrength, 2.0);
    
    // Random trigger for a shiver event
    float shiverTrigger = rand(vec2(offset, floor(time / interval)));
    
    // Only trigger if random number is above threshold (rarely happens)
    float isShivering = step(0.85, shiverTrigger);

    // If shivering, oscillate quickly for a short time
    float shiverPhase = fract(time * 2.0); // Very quick flicker between 0-1
    float shiverMotion = (shiverPhase < 0.5) ? 1.0 : -1.0; // Snap left/right
    
    float strength = clamp(minStrength + diff, minStrength, maxStrength) * strengthScale;

    float wind = shiverMotion * isShivering * strength * max(0.0, (1.0 - uv.y) - heightOffset);
    
    return wind; 
}

void vertex() {
    vec4 pos = MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0);
    float time = TIME * speed + offset;
    VERTEX.x += getWind(VERTEX.xy, UV, time);
}