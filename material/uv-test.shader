shader_type spatial;
render_mode blend_mix, depth_draw_alpha_prepass;

varying vec2 uv;

void vertex() {
	uv = UV;
}

void fragment() {
  ALBEDO = vec3(fract(uv.r * 64.0), fract(uv.g * 64.0), 0.5);
}