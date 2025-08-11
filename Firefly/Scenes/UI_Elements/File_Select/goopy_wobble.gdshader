shader_type canvas_item;

/*  Half-extents in UV-space (0–1) before aspect correction */
uniform vec2  SIZE   = vec2(0.4, 0.2);

/*  Corner radius in UV units relative to the *height* (0.1 = 10 % of height) */
uniform float RADIUS : hint_range(0.0, 0.5) = 0.1;

/*  Hand the shader the node’s aspect ratio (width / height).             
    You can fetch it from script and set the material parameter, e.g.:
        material.set_shader_parameter("ASPECT", rect_size.x / rect_size.y); */
uniform float ASPECT = 1.0;   // e.g. 1.77778 for 16:9, 0.75 for 3:4

/*  Wobble controls (unchanged) */
uniform float waveFrequency       : hint_range(0.0, 50.0) = 10.0;
uniform float waveAmplitude       : hint_range(0.0,  0.5) = 0.02;
uniform float waveSpeed           : hint_range(0.0, 10.0) = 2.0;
uniform float goopyness           : hint_range(0.0,  1.0) = 1.0;
uniform float distortion_strength : hint_range(0.0,  1.0) = 1.0;
uniform bool  hard_edges = true;
uniform float seed       = 0.0;

/* ─────────────── simple noise helpers ─────────────── */
float hash(vec2 p){ return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453123); }
float noise(vec2 p,float off){
    vec2 i=floor(p), f=fract(p);
    float a=hash(i+vec2(0,0)+off), b=hash(i+vec2(1,0)+off);
    float c=hash(i+vec2(0,1)+off), d=hash(i+vec2(1,1)+off);
    vec2 u=f*f*(3.0-2.0*f);
    return mix(a,b,u.x)+(c-a)*u.y*(1.0-u.x)+(d-b)*u.x*u.y;
}

/* ───────── aspect-correct rounded-box SDF ────────── */
float rounded_rect_sdf(vec2 uv, vec2 halfUV, float radiusUV, float aspect)
{
    /* stretch X so that 1 unit in X ~= 1 unit in Y */
    vec2 scale = vec2(aspect, 1.0);

    vec2 p = (uv - vec2(0.5)) * scale;      // centred, isotropic space
    vec2 h = halfUV * scale;                // half-extents in same space
    float r = radiusUV * scale.y;           // radius in same units

    vec2 q = abs(p) - (h - vec2(r));
    vec2 clamped  = max(q, vec2(0.0));
    float outside = length(clamped);        // distance outside the core box
    float inside  = min(max(q.x, q.y), 0.0);/* negative distance inside */
    return outside + inside - r;
}

/* ───────── wobble mixer (unchanged) ───────── */
float blended_distortion(vec2 uv,float f,float a,float s,float off){
    float sine = sin(uv.y*f + TIME*s + off);
    float n    = noise(uv*f + vec2(TIME*s,0.0), off);
    float goop = (n-0.5)*2.0;
    return mix(sine,goop,goopyness) * a * distortion_strength;
}

/* ───────── main ───────── */
void fragment()
{
    vec2 uv = UV;

    float sdf = rounded_rect_sdf(uv, SIZE, RADIUS, ASPECT);
    sdf += blended_distortion(uv, waveFrequency,
                                   waveAmplitude,
                                   waveSpeed,
                                   seed);

    float alpha = hard_edges ? step(0.0,-sdf)
                             : smoothstep(0.0,0.01,-sdf);

    COLOR.a *= alpha;
}