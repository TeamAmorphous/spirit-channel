shader_type canvas_item;

//uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

//Noise Texture
uniform sampler2D noise;

//Settings
uniform float slow = 25.0;
uniform float multiplier = 0.5;
uniform float contrast = 2.0;

//Shader Code
void fragment() {
	vec4 noise_sample = texture(noise, texture(noise, UV).xy + mod(TIME, 1.0) / slow);
	noise_sample.rgb = pow(noise_sample.rgb, vec3(contrast));
	COLOR = (noise_sample * multiplier);
}