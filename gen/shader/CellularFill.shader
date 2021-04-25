shader_type canvas_item;

uniform sampler2D u_brush_texture;
uniform float u_factor = 1.0;
uniform vec4 u_color = vec4(1.0);

uniform int u_death = 3;
uniform float u_birth = 1.5;
uniform float u_luminance = 0.5;
uniform float u_min = 0.5;
uniform bool u_deathnoise = false;

uniform vec2 u_offset;
uniform vec2 u_size;
uniform float u_scale:hint_range(0.0001, 1000.0);


float cell(sampler2D heightmap, vec2 uv, vec2 pixel_size, float weight) {
	float r = 1.0;
	float count = 0.0;
	// Divide so the shader stays neighbor dependent 1 pixel across.
	// For this to work, filtering must be enabled.
	vec2 eps = pixel_size / r;
	

	
	vec2 _uv = uv / eps;
	_uv.x = float(int(_uv.x))*eps.x;
	_uv.y = float(int(_uv.y))*eps.y;
	_uv += eps * 0.5;
	float h = texture(heightmap, _uv).r;
	uv = _uv;
	
	if (h == 1.0) {
		 return 1.0;
	}
	
	if (uv.x < 0.02 || uv.y < 0.02 || uv.x > 0.98 || uv.y > 0.98) {
		return 0.5;
	}
	
	for (float y = -r; y <= r; ++y) {
		for (float x = -r; x <= r; ++x) {
			vec2 p = vec2(x, y);
			float nh = texture(heightmap, uv + p * eps).r;
			if (nh > 0.0 && nh < 0.75) {
				count++;
				break;
			}
		}
	}
	if (count != 0.0) {
		return 0.5;
	}
	return 0.0;
}

void fragment() {
	float brush_value = texture(u_brush_texture, SCREEN_UV).r * u_factor;
	float ph = cell(TEXTURE, UV, TEXTURE_PIXEL_SIZE, brush_value);
	//ph += brush_value * 0.35;
	COLOR = vec4(ph, ph, ph, 1.0);
}