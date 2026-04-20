shader_type spatial;

uniform sampler2D screen_tex : source_color;
uniform float glow_strength = 0.5;
uniform float falloff = 2.0;

void fragment() {
	vec3 base_color = ALBEDO;

	// Convert screen UV to centered coords (-1 to 1)
	vec2 centered_uv = UV * 2.0 - 1.0;

	vec2 dir = normalize(centered_uv);
	vec2 sample_uv = (centered_uv - dir * 0.3) * 0.6 + 0.5;

    // Clamp so we don't sample outside
	sample_uv = clamp(sample_uv, vec2(0.0), vec2(1.0));

    // Sample the screen
	vec3 screen_color = texture(screen_tex, sample_uv).rgb;

    // Get brightness
	float brightness = dot(screen_color, vec3(0.299, 0.587, 0.114));

    // Distance from center (bezel = farther away)
	float dist = length(centered_uv);

    // Falloff so only inner bezel is affected
    float influence = pow(clamp(1.0 - dist, 0.0, 1.0), falloff);

    // Final glow contribution
	vec3 glow = screen_color * brightness * influence * glow_strength;

    ALBEDO = base_color + glow;
	EMISSION = glow * 1.5;
}