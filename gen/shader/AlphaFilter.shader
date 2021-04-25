shader_type canvas_item;
uniform vec4 u_color = vec4(1.0);

float random (vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898,78.233)))*43758.5453123);
}

void fragment() {
	
//	vec2 _f = TEXTURE_PIXEL_SIZE / 1.0;
//	vec2 _uv = UV / _f;
//	_uv.x = float(int(_uv.x))*_f.x;
//	_uv.y = float(int(_uv.y))*_f.y;
//	float ph = texture(TEXTURE, _uv - _f * 0.5).r;
	float ph = texture(TEXTURE, UV).r;
	if (ph == 0.0) {
		COLOR = vec4(0.0);
	} else {
		COLOR = u_color;
	}
	
}