shader_type canvas_item;

uniform vec2 player_screen_pos = vec2(0.0, 0.0);
uniform vec2 player_world_pos = vec2(0.0, 0.0);
uniform float spotlight_radius : hint_range(0.0, 200.0) = 64.0;
uniform float fade_radius : hint_range(0.0, 50.0) = 10.0;
uniform float min_alpha : hint_range(0.0, 1.0) = 0.0;

// Stylization parameters
uniform bool pixelated_edge = true;
uniform int edge_steps : hint_range(2, 16) = 8;
uniform bool animated_edge = false;
uniform float animation_speed : hint_range(0.1, 5.0) = 1.0;
uniform bool dithering = false;
uniform vec3 fog_color : source_color = vec3(0.1, 0.1, 0.2);
uniform float fog_blend : hint_range(0.0, 1.0) = 0.3;

// Wobbly parameters
uniform float wobbliness : hint_range(0.0, 1.0) = 0.0;
uniform float wobble_frequency : hint_range(0.1, 10.0) = 2.0;
uniform float wobble_speed : hint_range(0.1, 5.0) = 1.0;
uniform int wobble_octaves : hint_range(1, 4) = 2;
uniform float wobble_world_scale : hint_range(0.001, 0.1) = 0.01;

// Optimized noise functions
float hash21(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float smooth_noise(vec2 uv) {
    vec2 i = floor(uv);
    vec2 f = fract(uv);
    
    float a = hash21(i);
    float b = hash21(i + vec2(1.0, 0.0));
    float c = hash21(i + vec2(0.0, 1.0));
    float d = hash21(i + vec2(1.0, 1.0));
    
    vec2 u = smoothstep(0.0, 1.0, f);
    
    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

float optimized_fbm(vec2 uv, int octaves, float initial_amp) {
    float value = 0.0;
    float amplitude = initial_amp;
    float frequency = 1.0;
    float max_value = 0.0;
    
    for(int i = 0; i < 4; i++) {
        if(i >= octaves) break;
        
        value += amplitude * smooth_noise(uv * frequency);
        max_value += amplitude;
        
        frequency *= 2.0;
        amplitude *= 0.5;
    }
    
    return value / max_value;
}

void fragment() {
    vec2 fragment_screen_pos = FRAGCOORD.xy;
    vec2 direction_to_player = fragment_screen_pos - player_screen_pos;
    float base_distance = length(direction_to_player);
    
    float max_effect_radius = spotlight_radius + fade_radius + (wobbliness * 50.0);
    float distance_to_player = base_distance;
    
    // Only calculate wobble if it's actually enabled and we're in range
    if (wobbliness > 0.001 && base_distance <= max_effect_radius) {
        vec2 fragment_world_pos = player_world_pos + direction_to_player;
        vec2 noise_base = fragment_world_pos * wobble_world_scale * wobble_frequency;
        float time_factor = TIME * wobble_speed;
        
        float noise1 = optimized_fbm(noise_base + vec2(time_factor * 0.5, time_factor * 0.3), wobble_octaves, 0.5);
        float wobble_offset = noise1 * wobbliness * 30.0;
        
        if (wobble_octaves > 1) {
            float noise2 = optimized_fbm(noise_base * 1.3 + vec2(time_factor * 0.7, time_factor * 0.4), max(wobble_octaves - 1, 1), 0.25);
            wobble_offset += noise2 * wobbliness * 15.0;
        }
        
        float angle = atan(direction_to_player.y, direction_to_player.x);
        float radial_noise = smooth_noise(vec2(angle * 3.0 + time_factor, length(fragment_world_pos) * 0.01));
        wobble_offset += radial_noise * wobbliness * 10.0;
        
        distance_to_player = base_distance + wobble_offset;
    }
    
    // Only apply effects if within range
    if (base_distance <= max_effect_radius) {
        float animated_radius = spotlight_radius;
        if (animated_edge) {
            animated_radius += sin(TIME * animation_speed + player_world_pos.x * 0.001) * 3.0;
        }
        
        float alpha = 1.0;
        
        if (distance_to_player <= animated_radius) {
            alpha = min_alpha;
        } else if (distance_to_player <= animated_radius + fade_radius) {
            float fade_factor = (distance_to_player - animated_radius) / fade_radius;
            
            if (pixelated_edge) {
                fade_factor = floor(fade_factor * float(edge_steps)) / float(edge_steps);
            }
            
            if (dithering) {
                float noise = hash21(FRAGCOORD.xy * 0.5) * 0.1;
                fade_factor += noise;
            }
            
            alpha = mix(min_alpha, 1.0, fade_factor);
        }
        
        if (alpha < 0.8 && fog_blend > 0.001) {
            COLOR.rgb = mix(COLOR.rgb, fog_color, fog_blend * (1.0 - alpha));
        }
        
        COLOR.a *= alpha;
    }
}