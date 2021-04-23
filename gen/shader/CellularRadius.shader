shader_type canvas_item;

uniform float u_alive = 0.4;
uniform vec2 u_offset;

float random (vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898,78.233)))*43758.5453123);
}

float easeInOut(float t, float b, float c, float d) {
	t = (t / (d / 2.0));
	if (t < 1.0) {
		return c / 2.0 * t * t * t * t + b;
	}
	t = t - 2.0;
	return -c / 2.0 * (t * t * t * t - 2.0) + b;
}

float cell(vec2 uv) {
	float p_dist = distance(uv, vec2(0.5));
	float centerness = easeInOut(1.0 - p_dist / 0.70710678118, 0.0, 1.0, 1.0);
	if (random(u_offset + uv * 20.0) < u_alive * centerness) {
		return 1.0;
	}
	return 0.0;
}

void fragment() {
	vec2 _f = TEXTURE_PIXEL_SIZE / 1.0;
	vec2 _uv = UV / _f;
	_uv.x = float(int(_uv.x))*_f.x;
	_uv.y = float(int(_uv.y))*_f.y;
	float ph = max(cell(_uv), texture(TEXTURE, UV).r);

	COLOR = vec4(ph, ph, ph, 1.0);
}