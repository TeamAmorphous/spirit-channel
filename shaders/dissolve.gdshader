shader_type canvas_item;

uniform sampler2D noiseTexture: repeat_enable;
uniform vec4 edge_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float scale : hint_range(1.0, 10.0) = 2.0;
uniform float edge_value : hint_range(0.0, 1.0) = 0.2;
uniform float dissolve_value : hint_range(-1.0, 1.0) = 0.5;

void fragment() {
    vec4 main_tex = texture(TEXTURE, UV);
    
    // Create animated procedural noise
    float n = texture(noiseTexture, UV * scale).r;
    
    // Hard discard for the dissolve
    if (n < dissolve_value) {
        discard;
    }
    
    // Calculate the glowing edge
    float edge_intensity = smoothstep(dissolve_value + edge_value, dissolve_value, n);
    
    vec3 final_rgb = mix(main_tex.rgb, edge_color.rgb, edge_intensity * edge_color.a);
    
    COLOR = vec4(final_rgb, main_tex.a);
}