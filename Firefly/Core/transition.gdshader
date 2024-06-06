shader_type canvas_item;

// Ranges from 0 to 1 over the course of the transition.
// We use this to actually animate the shader.
uniform float progress : hint_range(0, 2);

// Size of each diamond, in pixels.
uniform float diamondPixelSize : hint_range(1, 1920) = 10;


float when_lt(float x, float y) {
    return max(sign(y - x), 0.0);
}

void fragment() {
    float xFraction = fract(FRAGCOORD.x / diamondPixelSize);
    float yFraction = fract(FRAGCOORD.y / diamondPixelSize);
    float xDistance = abs(xFraction - 0.5);
    float yDistance = abs(yFraction - 0.5);
    float distance = sqrt(xDistance * xDistance + yDistance * yDistance);
    float starShape = sin(5.0 * atan(yFraction - 0.5, xFraction - 0.5)) * 0.5 + 0.5;
    COLOR.a *= when_lt(distance * starShape + UV.x + UV.y, progress * 2.0f);
}