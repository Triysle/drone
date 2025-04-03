shader_type canvas_item;

// Controls the static noise intensity
uniform float noise_strength : hint_range(0.0, 1.0) = 0.7;
// Controls how quickly the static changes
uniform float noise_speed : hint_range(0.0, 10.0) = 5.0;
// Controls pixel size (smaller = larger pixels)
uniform float pixel_density : hint_range(10.0, 200.0) = 80.0;
// Original texture opacity
uniform float original_strength : hint_range(0.0, 1.0) = 0.3;
// Offset for panning effect
uniform vec2 offset = vec2(0.0, 0.0);
// Zoom factor to prevent edge distortion
uniform float zoom_factor : hint_range(1.0, 1.5) = 1.05;

// Random function - returns a random value based on coordinates
float random(vec2 uv) {
    return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453123);
}

void fragment() {
    // Apply zoom factor and center the zoom effect
    vec2 centered_uv = UV - 0.5;
    vec2 zoomed_uv = centered_uv / zoom_factor + 0.5;
    
    // Offset the UV coordinates for panning
    vec2 panned_uv = zoomed_uv + offset;
    
    // Get the original texture color (or use black if none)
    // Clamp to ensure we don't sample outside the texture boundaries
    vec4 original_color = texture(TEXTURE, clamp(panned_uv, vec2(0.0), vec2(1.0)));
    
    // Create pixelated coordinates
    vec2 pixelated_uv = floor(UV * pixel_density) / pixel_density;
    
    // Generate time-based offset for animation
    float time_offset = TIME * noise_speed;
    
    // Generate noise with pixelated coordinates
    float noise_value = random(pixelated_uv + vec2(0.1, 0.2) + time_offset);
    
    // Create black and white static noise color
    vec4 noise_color = vec4(noise_value, noise_value, noise_value, 1.0);
    
    // Mix the original texture with the noise based on the strength parameters
    COLOR = mix(original_color * original_strength, noise_color, noise_strength);
}