shader_type canvas_item;

uniform sampler2D u_brush_texture;
uniform float u_factor = 1.0;
uniform vec4 u_color = vec4(1.0);
uniform float u_low = 0;

float erode(sampler2D heightmap, vec2 uv, vec2 pixel_size, float weight) {
	float r = 1.0;
	
	// Divide so the shader stays neighbor dependent 1 pixel across.
	// For this to work, filtering must be enabled.
	vec2 eps = pixel_size /  r;
	
	float h = texture(heightmap, uv).r;
	float eh = h;
	
	// Morphology with circular structuring element
	for (float y = -r; y <= r; ++y) {
		for (float x = -r; x <= r; ++x) {
			vec2 p = vec2(x, y);
			float nh = texture(heightmap, uv + p * eps).r;
			
			float s = max(length(p) - r, 0);
			eh = min (eh, nh + s);
		}
	}
	
	return mix(h, eh, weight);
}

float erode2(sampler2D heightmap, vec2 uv, vec2 pixel_size, float weight, float h) {
	float r = 1.0;
	
	// Divide so the shader stays neighbor dependent 1 pixel across.
	// For this to work, filtering must be enabled.
	vec2 eps = pixel_size /  r;

	float eh = h;
	
	// Morphology with circular structuring element
	for (float y = -r; y <= r; ++y) {
		for (float x = -r; x <= r; ++x) {
			vec2 p = vec2(x, y);
			float nh = texture(heightmap, uv + p * eps).r;
			
			float s = max(length(p) - r, 0);
			eh = max (eh, nh - s );
		}
	}
	
	return mix(h, eh, weight);
}

float expand(sampler2D heightmap, vec2 uv, vec2 pixel_size, float weight, float h) {
	float r = 3.0;
	
	// Divide so the shader stays neighbor dependent 1 pixel across.
	// For this to work, filtering must be enabled.
	vec2 eps = pixel_size /  r;
	

	float eh = h;
	
	// Morphology with circular structuring element
	for (float y = -r; y <= r; ++y) {
		for (float x = -r; x <= r; ++x) {
			vec2 p = vec2(x, y);
			float nh = texture(heightmap, uv + p * eps).r;
			
			float s = max(length(p) - r, 0);
			eh = min (eh, nh + s);
		}
	}
	
	return mix(h, eh, weight);
}

void fragment() {
	float ph = erode(TEXTURE, UV, TEXTURE_PIXEL_SIZE*0.5, u_factor);
	ph = erode2(TEXTURE, UV, TEXTURE_PIXEL_SIZE*0.5, u_factor, ph);
	//ph += brush_value * 0.35;
	COLOR = vec4(ph, ph, ph, 1.0);
}