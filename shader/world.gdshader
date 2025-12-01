shader_type canvas_item;
render_mode unshaded, skip_vertex_transform;

const float target_curvature = 4.6;
const float vignette_multiplier = 0.09;

uniform float curvature_progress : hint_range(0.0, 1.0) = 0.0;
uniform sampler2D screen_texture: hint_screen_texture, filter_linear_mipmap;

void fragment() {
	// Interpolar la curvatura de 0.0 a target_curvature
	float curvature = mix(0.0, target_curvature, curvature_progress);
	
	// Evitar división por cero cuando curvature es 0
	float safe_curvature = max(curvature, 0.001);
	
	vec2 centered_uv = SCREEN_UV * 2.0 - 1.0;
	vec2 uv_offset = centered_uv.yx / safe_curvature;
	vec2 warped_uv = centered_uv + centered_uv * uv_offset * uv_offset;
	vec3 cutoff = vec3(step(abs(warped_uv.x), 1.0) * step(abs(warped_uv.y), 1.0));
	vec3 scanlines = vec3(sin(2.0 * warped_uv.y * 180.0) * 0.1 + 0.9);
	vec3 vignette = vec3(length(pow(abs(centered_uv), vec2(4.0)) / 3.0));
	
	vec3 screen_color = textureLod(screen_texture, (warped_uv + 1.0) / 2.0, 0.2).rgb * cutoff * scanlines;
	screen_color -= vignette * vignette_multiplier;
	COLOR = vec4(screen_color, 1.0);
}