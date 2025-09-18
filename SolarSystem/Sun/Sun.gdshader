shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque, depth_test_disabled;

uniform float intensity : hint_range(0.0, 10.0) = 3.0;
uniform float speed : hint_range(0.0, 3.0) = 1.0;
uniform vec3 sun_color : source_color = vec3(1.0, 0.7, 0.2);
uniform vec3 core_color : source_color = vec3(1.0, 0.9, 0.6);
uniform float surface_detail : hint_range(0.0, 1.0) = 0.3;
uniform float flicker_strength : hint_range(0.0, 0.5) = 0.1;
uniform float corona_size : hint_range(1.0, 3.0) = 1.5;

varying vec3 world_position;
varying vec3 local_position;

// Simple noise function
float noise(vec3 p) {
    return fract(sin(dot(p, vec3(12.9898, 78.233, 45.164))) * 43758.5453);
}

// Smooth 3D noise
float smooth_noise(vec3 p) {
    vec3 i = floor(p);
    vec3 f = fract(p);
    
    f = f * f * (3.0 - 2.0 * f);
    
    return mix(
        mix(mix(noise(i + vec3(0,0,0)), noise(i + vec3(1,0,0)), f.x),
            mix(noise(i + vec3(0,1,0)), noise(i + vec3(1,1,0)), f.x), f.y),
        mix(mix(noise(i + vec3(0,0,1)), noise(i + vec3(1,0,1)), f.x),
            mix(noise(i + vec3(0,1,1)), noise(i + vec3(1,1,1)), f.x), f.y), f.z);
}

// Fractal Brownian Motion for complex surface
float fbm(vec3 p) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;
    
    for (int i = 0; i < 4; i++) {
        value += amplitude * smooth_noise(p * frequency);
        amplitude *= 0.5;
        frequency *= 2.0;
    }
    return value;
}

void vertex() {
    world_position = VERTEX;
    local_position = VERTEX;
}

void fragment() {
    vec3 pos = local_position;
    float dist_from_center = length(pos);
    
    // Animate the surface
    vec3 animated_pos = pos + vec3(
        sin(TIME * speed * 0.7) * 0.1,
        cos(TIME * speed * 0.5) * 0.1,
        sin(TIME * speed * 0.3) * 0.1
    );
    
    // Create surface turbulence
    float surface_noise = fbm(animated_pos * 3.0 + TIME * speed * 0.5);
    surface_noise = surface_noise * 0.5 + 0.5;
    
    // Fresnel-like effect for edge glow
    vec3 normal = normalize(local_position);
    vec3 view_dir = normalize(CAMERA_POSITION_WORLD - world_position);
    float fresnel = 1.0 - abs(dot(normal, view_dir));
    fresnel = pow(fresnel, 2.0);
    
    // Core intensity based on distance from center
    float core_intensity = 1.0 - smoothstep(0.0, 1.0, dist_from_center);
    
    // Surface variation
    float surface_variation = surface_noise * surface_detail + (1.0 - surface_detail);
    
    // Flickering effect
    float flicker = 1.0 + sin(TIME * 20.0 + surface_noise * 15.0) * flicker_strength;
    
    // Color mixing
    vec3 final_color = mix(sun_color, core_color, core_intensity * 0.7);
    
    // Add surface detail
    final_color *= surface_variation;
    
    // Add edge glow/corona
    final_color += sun_color * fresnel * corona_size * 0.3;
    
    // Apply intensity and flickering
    final_color *= intensity * flicker;
    
    ALBEDO = final_color;
    EMISSION = final_color;
    
    // Make edges more transparent for corona effect
    ALPHA = mix(1.0, fresnel * 2.0, 0.3);
}