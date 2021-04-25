shader_type canvas_item;

void fragment() {
	float ph = texture(TEXTURE, UV).r;
	if (ph < 0.5) {
		ph = 0.0
	} else {
		ph = 1.0
	}
	COLOR = vec4(ph, ph, ph, 1.0);
}