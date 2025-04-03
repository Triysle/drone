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

// Search effect - Sweeping highlight
uniform float search_effect_active = 0.0;
uniform float search_sweep_progress : hint_range(0.0, 1.0) = 0.0;
uniform float search_sweep_width : hint_range(0.0, 0.5) = 0.1;
uniform float search_highlight_intensity : hint_range(0.0, 1.0) = 0.7;

// Scan effect - Circular scanning pulse
uniform float scan_effect_active = 0.0;
uniform float scan_pulse_progress : hint_range(0.0, 1.0) = 0.0;
uniform float scan_pulse_width : hint_range(0.0, 0.5) = 0.1;
uniform float scan_highlight_intensity : hint_range(0.0, 1.0) = 0.7;

// Salvage effect - Extraction glow
uniform float salvage_effect_active = 0.0;
uniform vec2 salvage_center = vec2(0.5, 0.5);
uniform float salvage_radius : hint_range(0.0, 0.5) = 0.2;
uniform float salvage_glow_intensity : hint_range(0.0, 1.0) = 0.7;
uniform float salvage_pulse_progress : hint_range(0.0, 1.0) = 0.0;

// Random function - returns a random value based on coordinates
float random(vec2 uv) {
    return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453123);
}

void fragment() {
    // Offset the UV coordinates for panning
    vec2 panned_uv = UV + offset;
    
    // Get the original texture color (or use black if none)
    vec4 original_color = texture(TEXTURE, panned_uv);
    
    // Create pixelated coordinates
    vec2 pixelated_uv = floor(UV * pixel_density) / pixel_density;
    
    // Generate time-based offset for animation
    float time_offset = TIME * noise_speed;
    
    // Generate noise with pixelated coordinates
    float noise_value = random(pixelated_uv + vec2(0.1, 0.2) + time_offset);
    
    // Create black and white static noise color
    vec4 noise_color = vec4(noise_value, noise_value, noise_value, 1.0);
    
    // Mix the original texture with the noise based on the strength parameters
    vec4 result_color = mix(original_color * original_strength, noise_color, noise_strength);
    
    // Apply Search Effect - Horizontal sweeping highlight
    if (search_effect_active > 0.0) {
        float sweep_position = search_sweep_progress; // 0.0 to 1.0 across screen
        float distance_from_sweep = abs(UV.y - sweep_position);
        
        if (distance_from_sweep < search_sweep_width) {
            // Calculate falloff based on distance from center of sweep
            float falloff = 1.0 - (distance_from_sweep / search_sweep_width);
            // Apply highlight
            result_color = mix(result_color, vec4(1.0), falloff * search_highlight_intensity * search_effect_active);
        }
    }
    
    // Apply Scan Effect - Circular pulse
    if (scan_effect_active > 0.0) {
        vec2 center = vec2(0.5, 0.5);
        float distance_from_center = distance(UV, center);
        float pulse_position = scan_pulse_progress * 0.5; // Pulse moves from center to edge
        
        if (abs(distance_from_center - pulse_position) < scan_pulse_width) {
            // Calculate falloff based on distance from pulse
            float falloff = 1.0 - abs(distance_from_center - pulse_position) / scan_pulse_width;
            // Apply highlight with a blue tint (for a technical look)
            vec4 pulse_color = vec4(0.2, 0.4, 1.0, 1.0); 
            result_color = mix(result_color, pulse_color, falloff * scan_highlight_intensity * scan_effect_active);
        }
    }
    
    // Apply Salvage Effect - Extraction glow
    if (salvage_effect_active > 0.0) {
        float distance_from_point = distance(UV, salvage_center);
        
        if (distance_from_point < salvage_radius) {
            // Pulse effect for the glow
            float pulse = sin(salvage_pulse_progress * 3.14159) * salvage_glow_intensity;
            
            // Apply glow - bright yellow/orange to suggest extraction of valuable parts
            vec4 glow_color = vec4(1.0, 0.8, 0.2, 1.0);
            float glow_factor = (1.0 - distance_from_point / salvage_radius) * pulse * salvage_effect_active;
            result_color = mix(result_color, glow_color, glow_factor);
        }
    }
    
    COLOR = result_color;
}