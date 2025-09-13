shader_type sky;

// =============================================================================
// STARRY SKY SHADER - Two-layer star system
// Layer 1: Distant stars (lots of tiny pinpoints)
// Layer 2: Close stars (fewer, larger, more colorful)
// =============================================================================

// Layer toggles
uniform bool show_distant_stars = true;
uniform bool show_close_stars = false;

// Distant star layer (background)
uniform float distant_density : hint_range(0.0, 2.0) = 0.8;
uniform float distant_brightness : hint_range(0.0, 1.0) = 0.4;
uniform float distant_size : hint_range(0.005, 0.05) = 0.015;
uniform float distant_color_variation : hint_range(0.0, 1.0) = 0.3;

// Close star layer (foreground)
uniform float close_density : hint_range(0.0, 0.3) = 0.1;
uniform float close_brightness : hint_range(0.1, 3.0) = 1.5;
uniform float close_size : hint_range(0.02, 0.2) = 0.08;
uniform float close_color_variation : hint_range(0.0, 1.0) = 0.7;

// Environment
uniform float background_brightness : hint_range(0.0, 0.1) = 0.02;

// =============================================================================
// UTILITY FUNCTIONS
// =============================================================================

// Fast 3D hash function - converts 3D position to random value [0,1]
float hash31(vec3 p) {
    p = fract(p * vec3(443.8975, 397.2973, 491.1871)); // Magic numbers for good distribution
    p += dot(p, p.yxz + 19.19);                         // Mix components
    return fract((p.x + p.y) * p.z);                   // Final hash
}

// Generate realistic star colors based on stellar temperature
// temp: 0.0 = cool red stars, 0.5 = sun-like, 1.0 = hot blue stars
vec3 getStarColor(float temp) {
    if (temp < 0.3) {
        // Red giants and cool stars
        return mix(vec3(1.0, 0.3, 0.1), vec3(1.0, 0.6, 0.2), temp / 0.3);
    } else if (temp < 0.7) {
        // Sun-like yellow/white stars
        return mix(vec3(1.0, 0.6, 0.2), vec3(1.0, 1.0, 0.9), (temp - 0.3) / 0.4);
    } else {
        // Hot blue/white stars
        return mix(vec3(1.0, 1.0, 0.9), vec3(0.7, 0.8, 1.0), (temp - 0.7) / 0.3);
    }
}

// =============================================================================
// MAIN SHADER
// =============================================================================

void sky() {
    vec3 dir = normalize(EYEDIR);
    vec3 final_color = vec3(0.0);

    // DISTANT STAR LAYER - Lots of tiny pinpoint stars
    if (show_distant_stars) {
        vec3 pos = dir * 20.0;  // Large scale for distant feeling
        vec3 grid_id = floor(pos);
        vec3 grid_pos = fract(pos);

        // Check if this cell has a star
        float rand1 = hash31(grid_id);
        if (rand1 < distant_density) {
            // Star position within cell
            float rand2 = hash31(grid_id + vec3(111.0));
            float rand3 = hash31(grid_id + vec3(222.0));
            vec2 star_pos = vec2(rand2, rand3) * 0.8 + 0.1;

            float dist = length(grid_pos.xy - star_pos);
            float star_intensity = exp(-dist * 60.0 / distant_size) * distant_brightness;

            // Star color (mostly white with subtle hints)
            float temp_rand = hash31(grid_id + vec3(333.0));
            float temperature = 0.5 + (temp_rand - 0.5) * distant_color_variation;
            vec3 star_color = mix(vec3(1.0), getStarColor(temperature), distant_color_variation);

            final_color += star_color * star_intensity;
        }
    }

    // CLOSE STAR LAYER - Fewer, larger, more colorful stars
    if (show_close_stars) {
        vec3 pos = dir * 8.0;   // Smaller scale for closer feeling
        vec3 grid_id = floor(pos) + vec3(500.0); // Offset to avoid pattern overlap
        vec3 grid_pos = fract(pos);

        // Check if this cell has a star
        float rand1 = hash31(grid_id);
        if (rand1 < close_density) {
            // Star position within cell
            float rand2 = hash31(grid_id + vec3(111.0));
            float rand3 = hash31(grid_id + vec3(222.0));
            vec2 star_pos = vec2(rand2, rand3) * 0.6 + 0.2;

            float dist = length(grid_pos.xy - star_pos);
            float star_intensity = exp(-dist * 25.0 / close_size) * close_brightness;

            // Star color (full color variation)
            float temp_rand = hash31(grid_id + vec3(333.0));
            float temperature = mix(0.0, 1.0, temp_rand);
            temperature = mix(0.5, temperature, close_color_variation);
            vec3 star_color = getStarColor(temperature);

            final_color += star_color * star_intensity;
        }
    }

    // Space background with slight blue tint
    vec3 background = vec3(
        background_brightness * 0.5,  // Red
        background_brightness * 0.6,  // Green
        background_brightness * 1.0   // Blue
    );

    COLOR = background + final_color;
}