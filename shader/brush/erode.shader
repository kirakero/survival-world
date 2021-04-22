shader_type canvas_item;

uniform sampler2D u_brush_texture;
uniform float u_factor = 1.0;
uniform vec4 u_color = vec4(1.0);
uniform float u_low = 0;

float erode(sampler2D heightmap, vec2 uv, vec2 pixel_size, float weight) {
	float r = 3.0;
	
	// Divide so the shader stays neighbor dependent 1 pixel across.
	// For this to work, filtering must be enabled.
	vec2 eps = pixel_size / (0.99 * r);
	
	float h = texture(heightmap, uv).r;
	if (h <= u_low / 255.0) {
		return h;
	}
	float eh = h;
	
	// Morphology with circular structuring element
	for (float y = -r; y <= r; ++y) {
		for (float x = -r; x <= r; ++x) {
			vec2 p = vec2(x, y);
			float nh = texture(heightmap, uv + p * eps).r;
			
			float s = max(length(p) - r, 0);
			eh = min(eh, nh + s);
		}
	}
	
	return max(u_low / 255.0, mix(h, eh, weight));
}

void fragment() {
	float brush_value = texture(u_brush_texture, SCREEN_UV).r * u_factor;
	float ph = erode(TEXTURE, UV, TEXTURE_PIXEL_SIZE, brush_value);
	//ph += brush_value * 0.35;
	COLOR = vec4(ph, ph, ph, 1.0);
}