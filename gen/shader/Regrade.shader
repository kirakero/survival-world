shader_type canvas_item;

uniform float u_delta = 0.5;
uniform float u_low = 0.0;
uniform float u_high = 1.0;


void fragment() {
	float ph = texture(TEXTURE, UV).r;
	if (ph >= u_low && ph <= u_high) {
		ph = clamp(ph + u_delta, 0.0, 1.0);
	}
	COLOR = vec4(ph, ph, ph, 1.0);
}