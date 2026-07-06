// Gorme engelli bandi — sari, kabartma noktali, asinmis.
shader_type spatial;
render_mode cull_back;

uniform vec3 base_color : source_color = vec3(0.72, 0.55, 0.06);
uniform float dot_spacing = 0.062;
uniform float dot_radius = 0.016;
uniform float dot_height = 0.0045;
uniform float dirt_amount : hint_range(0.0, 1.0) = 0.5;
uniform float normal_strength : hint_range(0.0, 3.0) = 1.0;

varying vec3 wpos;
varying vec3 wnrm;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
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
		p = p * 2.13 + vec2(7.7);
		a *= 0.5;
	}
	return v;
}

float dome(vec2 uv) {
	vec2 g = (fract(uv / dot_spacing) - 0.5) * dot_spacing;
	float r = length(g);
	return dot_height * smoothstep(dot_radius, dot_radius * 0.3, r);
}

void fragment() {
	// yalnizca ust yuzeyler icin tasarlandi (zemin bandi)
	vec2 uv = wpos.xz;
	vec3 axis_u = vec3(1.0, 0.0, 0.0);
	vec3 axis_v = vec3(0.0, 0.0, 1.0);

	float e = dot_radius * 0.35;
	float hx = dome(uv + vec2(e, 0.0)) - dome(uv - vec2(e, 0.0));
	float hy = dome(uv + vec2(0.0, e)) - dome(uv - vec2(0.0, e));
	vec3 n_w = normalize(wnrm - (axis_u * hx + axis_v * hy) * (normal_strength * 0.5 / e));

	float d = dome(uv) / max(dot_height, 1e-5);
	float dirt = dirt_amount * (0.4 * fbm(uv * 3.0) + 0.25 * fbm(uv * 0.8));

	// nokta tepeleri asinmis, parlak; cukurlar kirli
	vec3 col = base_color * (0.75 + 0.35 * fbm(uv * 8.0));
	col *= 1.0 - dirt * (1.0 - d * 0.7);
	col += vec3(0.08) * smoothstep(0.7, 1.0, d);

	ALBEDO = col;
	ROUGHNESS = clamp(0.55 - d * 0.2 + (fbm(uv * 20.0) - 0.5) * 0.15 + dirt * 0.2, 0.05, 1.0);
	METALLIC = 0.0;
	SPECULAR = 0.45;
	NORMAL = normalize((VIEW_MATRIX * vec4(n_w, 0.0)).xyz);
}
