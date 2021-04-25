shader_type canvas_item;




void fragment() {
//	vec2 _f = TEXTURE_PIXEL_SIZE / 1.0;
//	vec2 _uv = UV / _f;
//	_uv.x = float(int(_uv.x))*_f.x;
//	_uv.y = float(int(_uv.y))*_f.y;
//	float ph = texture(TEXTURE, _uv - _f * 0.5).r;
	float ph = texture(TEXTURE, UV).r;
	if (ph < 0.5) {
		ph = 0.0
	} else {
		ph = 1.0
	}
	COLOR = vec4(ph, ph, ph, 1.0);
}