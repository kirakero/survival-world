shader_type canvas_item;

uniform sampler2D u_brush_texture;
uniform float u_factor = 1.0;
uniform vec4 u_color = vec4(1.0);

uniform int u_death = 3;
uniform float u_birth = 1.5;


uniform vec2 u_offset;
uniform float u_scale:hint_range(0.0001, 1000.0);


// Description : Array and textureless GLSL 2D simplex noise function.
//      Author : Ian McEwan, Ashima Arts.
//  Maintainer : stegu
//     Lastmod : 20110822 (ijm)
//     License : Copyright (C) 2011 Ashima Arts. All rights reserved.
//               Distributed under the MIT License. See LICENSE file.
//               https://github.com/ashima/webgl-noise
//               https://github.com/stegu/webgl-noise
// 

vec3 mod289_3(vec3 x) {
    return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec2 mod289_2(vec2 x) {
    return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec3 permute(vec3 x) {
    return mod289_3(((x*34.0)+1.0)*x);
}

float snoise(vec2 v) {
    vec4 C = vec4(0.211324865405187,  // (3.0-sqrt(3.0))/6.0
                  0.366025403784439,  // 0.5*(sqrt(3.0)-1.0)
                 -0.577350269189626,  // -1.0 + 2.0 * C.x
                  0.024390243902439); // 1.0 / 41.0
    // First corner
    vec2 i  = floor(v + dot(v, C.yy) );
    vec2 x0 = v -   i + dot(i, C.xx);
    
    // Other corners
    vec2 i1;
    //i1.x = step( x0.y, x0.x ); // x0.x > x0.y ? 1.0 : 0.0
    //i1.y = 1.0 - i1.x;
    i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
    // x0 = x0 - 0.0 + 0.0 * C.xx ;
    // x1 = x0 - i1 + 1.0 * C.xx ;
    // x2 = x0 - 1.0 + 2.0 * C.xx ;
    vec4 x12 = vec4(x0.xy, x0.xy) + C.xxzz;
    x12.xy -= i1;
    
    // Permutations
    i = mod289_2(i); // Avoid truncation effects in permutation
    vec3 p = permute( permute( i.y + vec3(0.0, i1.y, 1.0 ))
    	+ i.x + vec3(0.0, i1.x, 1.0 ));
    
    vec3 m = max(0.5 - vec3(dot(x0,x0), dot(x12.xy,x12.xy), dot(x12.zw,x12.zw)), vec3(0.0));
    m = m*m ;
    m = m*m ;
    
    // Gradients: 41 points uniformly over a line, mapped onto a diamond.
    // The ring size 17*17 = 289 is close to a multiple of 41 (41*7 = 287)
    
    vec3 x = 2.0 * fract(p * C.www) - 1.0;
    vec3 h = abs(x) - 0.5;
    vec3 ox = floor(x + 0.5);
    vec3 a0 = x - ox;
    
    // Normalise gradients implicitly by scaling m
    // Approximation of: m *= inversesqrt( a0*a0 + h*h );
    m *= 1.79284291400159 - 0.85373472095314 * ( a0*a0 + h*h );
    
    // Compute final noise value at P
    vec3 g;
    g.x  = a0.x  * x0.x  + h.x  * x0.y;
    g.yz = a0.yz * x12.xz + h.yz * x12.yw;
    return 130.0 * dot(m, g);
}


float cell(sampler2D heightmap, vec2 uv, vec2 pixel_size, float weight) {
	float r = 1.0;
	float count = 0.0;
	// Divide so the shader stays neighbor dependent 1 pixel across.
	// For this to work, filtering must be enabled.
	vec2 eps = pixel_size / r;
	
	// make sure the center is always present
	if (uv.x > 0.48 && uv.x < 0.52 && uv.y > 0.48 && uv.y < 0.52) {
		return 0.5;
	}
	
	vec2 _uv = uv / eps;
	_uv.x = float(int(_uv.x))*eps.x;
	_uv.y = float(int(_uv.y))*eps.y;
	_uv += eps * 0.5;
	float h = texture(heightmap, _uv).r;
	uv = _uv;
	
	for (float y = -r; y <= r; ++y) {
		for (float x = -r; x <= r; ++x) {
			if ( x == 0.0 && y == 0.0 ) {
				continue;
			}
			vec2 p = vec2(x, y);
			float nh = texture(heightmap, uv + p * eps).r;
			if (nh > 0.0) {
				count++;
			}
		}
	}
	uv = uv / eps;
	uv.x = float(int(uv.x));
	uv.y = float(int(uv.y));
	uv *= eps;
	if ( h > 0.0 && count < float(u_death) ) {
		return 0.0;
	} else if (count > u_birth - snoise((uv + u_offset) * u_scale)) {
		return 0.5;
	}
	
	return h;
}

void fragment() {
	float brush_value = texture(u_brush_texture, SCREEN_UV).r * u_factor;
	float ph = cell(TEXTURE, UV, TEXTURE_PIXEL_SIZE, brush_value);
	//ph += brush_value * 0.35;
	COLOR = vec4(ph, ph, ph, 1.0);
}