shader_type canvas_item;

// Controls the static noise intensity
uniform float noise_strength : hint_range(0.0, 1.0) = 0.3;
// Controls how quickly the static changes
uniform float noise_speed : hint_range(0.0, 10.0) = 5.0;
// Original texture opacity
uniform float original_strength : hint_range(0.0, 1.0) = 0.8;

// Random function - returns a random value based on coordinates
float random(vec2 uv) {
    return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453123);
}

void fragment() {
    // Get the original texture color
    vec4 original_color = texture(TEXTURE, UV);
    
    // Generate time-based offset for animation
    float time_offset = TIME * noise_speed;
    
    // Generate noise for red, green, and blue channels
    float noise_r = random(UV + vec2(0.1, 0.2) + time_offset);
    float noise_g = random(UV + vec2(0.3, 0.4) + time_offset);
    float noise_b = random(UV + vec2(0.5, 0.6) + time_offset);
    
    // Create static noise color
    vec4 noise_color = vec4(noise_r, noise_g, noise_b, 1.0);
    
    // Mix the original texture with the noise based on the strength parameters
    COLOR = mix(original_color * original_strength, noise_color, noise_strength);
}