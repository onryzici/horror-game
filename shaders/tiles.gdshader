// Prosedurel fayans — triplanar (dunya uzayi), derz + pah + karo bazli varyasyon.
// Fotorealizmin kalbi: her karonun mikro egimi (lippage) yansimalari kirar.
shader_type spatial;
render_mode cull_back;

uniform vec3 tile_color : source_color = vec3(0.85, 0.86, 0.84);
uniform vec3 grout_color : source_color = vec3(0.15, 0.16, 0.17);
uniform float tile_size = 0.10;
uniform float grout_width = 0.006;
uniform float bevel_width = 0.007;
uniform float tile_roughness : hint_range(0.0, 1.0) = 0.16;
uniform float grout_roughness : hint_range(0.0, 1.0) = 0.9;
uniform float color_variation : hint_range(0.0, 1.0) = 0.4;
uniform float tilt_variation : hint_range(0.0, 1.0) = 0.6;
uniform float streak_amount : hint_range(0.0, 1.0) = 0.2;
uniform float dirt_amount : hint_range(0.0, 1.0) = 0.35;
uniform float normal_strength : hint_range(0.0, 3.0) = 1.0;

varying vec3 wpos;
varying vec3 wnrm;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

vec2 hash22(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.xx + p3.yz) * p3.zy);
}

float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	float a = hash12(i);
	float b = hash12(i + vec2(1.0, 0.0));
	float c = hash12(i + vec2(0.0, 1.0));
	float d = hash12(i + vec2(1.0, 1.0));
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 3; i++) {
		v += a * vnoise(p);
		p = p * 2.13 + vec2(17.7);
		a *= 0.5;
	}
	return v;
}

float tile_height(vec2 uv) {
	vec2 cuv = uv / tile_size;
	vec2 cell = floor(cuv);
	vec2 f = fract(cuv) * tile_size;
	float gh = grout_width * 0.5;
	vec2 d2 = min(f, vec2(tile_size) - f) - vec2(gh);
	float d = min(d2.x, d2.y);
	float h = smoothstep(0.0, bevel_width, d);
	vec2 rnd = hash22(cell);
	vec2 tilt = (rnd - 0.5) * tilt_variation * 0.008;
	float base = h * 0.0016;
	base += dot(f - vec2(tile_size * 0.5), tilt) * h;
	base += (rnd.y - 0.5) * 0.0009 * tilt_variation * h;
	return base;
}

void fragment() {
	vec3 an = abs(wnrm);
	vec2 uv;
	vec3 axis_u;
	vec3 axis_v;
	if (an.y >= an.x && an.y >= an.z) {
		uv = wpos.xz;
		axis_u = vec3(1.0, 0.0, 0.0);
		axis_v = vec3(0.0, 0.0, 1.0);
	} else if (an.x >= an.z) {
		uv = wpos.zy;
		axis_u = vec3(0.0, 0.0, 1.0);
		axis_v = vec3(0.0, 1.0, 0.0);
	} else {
		uv = wpos.xy;
		axis_u = vec3(1.0, 0.0, 0.0);
		axis_v = vec3(0.0, 1.0, 0.0);
	}

	vec2 cuv = uv / tile_size;
	vec2 cell = floor(cuv);
	vec2 f = fract(cuv) * tile_size;
	float gh = grout_width * 0.5;
	vec2 d2 = min(f, vec2(tile_size) - f) - vec2(gh);
	float d = min(d2.x, d2.y);
	float grout_mask = 1.0 - smoothstep(0.0, 0.0016, d);

	// yukseklik alanindan sonlu farkla normal
	float e = max(tile_size * 0.015, 0.0008);
	float hx = tile_height(uv + vec2(e, 0.0)) - tile_height(uv - vec2(e, 0.0));
	float hy = tile_height(uv + vec2(0.0, e)) - tile_height(uv - vec2(0.0, e));
	vec3 n_w = normalize(wnrm - (axis_u * hx + axis_v * hy) * (normal_strength * 0.5 / e));

	// karo bazli renk varyasyonu
	float v1 = hash12(cell + 7.31);
	float v2 = hash12(cell + 3.17);
	vec3 tcol = tile_color * (1.0 + (v1 - 0.5) * 0.16 * color_variation);
	tcol *= mix(vec3(1.0), vec3(0.965, 1.0, 1.035), (v2 - 0.5) * 2.0 * color_variation);
	// karo ici mermer damarlari
	float streak = fbm(uv * 9.0 + hash22(cell) * 37.0);
	tcol *= 1.0 - streak_amount * 0.35 * (streak - 0.5);

	// kir: derz + zemine yakin + lekeler
	float blotch = fbm(uv * 0.7);
	float low = 1.0 - smoothstep(0.05, 1.4, wpos.y);
	float dirt = clamp(dirt_amount * (0.45 * blotch + 0.4 * low), 0.0, 1.0);

	vec3 gcol = grout_color * (0.8 + 0.4 * fbm(uv * 30.0));
	vec3 col = mix(tcol, gcol, grout_mask);
	col *= 1.0 - dirt * 0.4;

	float rough = mix(tile_roughness, grout_roughness, grout_mask);
	rough += (fbm(uv * 22.0) - 0.5) * 0.10 + dirt * 0.25;

	ALBEDO = col;
	ROUGHNESS = clamp(rough, 0.03, 1.0);
	METALLIC = 0.0;
	SPECULAR = mix(0.55, 0.2, grout_mask);
	AO = 1.0 - grout_mask * 0.35;
	AO_LIGHT_AFFECT = 0.4;
	NORMAL = normalize((VIEW_MATRIX * vec4(n_w, 0.0)).xyz);
}
