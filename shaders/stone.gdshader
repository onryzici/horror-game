// Koyu granit basamak — benek + fbm varyasyon + hafif parlaklik (islak his).
shader_type spatial;
render_mode cull_back;

uniform vec3 base_color : source_color = vec3(0.125, 0.135, 0.145);
uniform float rough_base : hint_range(0.0, 1.0) = 0.34;
uniform float speckle_amount : hint_range(0.0, 1.0) = 0.6;
uniform float wear_amount : hint_range(0.0, 1.0) = 0.5;
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
		p = p * 2.13 + vec2(11.1);
		a *= 0.5;
	}
	return v;
}

float sheight(vec2 uv) {
	return fbm(uv * 18.0) * 0.0008;
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

	float e = 0.003;
	float hx = sheight(uv + vec2(e, 0.0)) - sheight(uv - vec2(e, 0.0));
	float hy = sheight(uv + vec2(0.0, e)) - sheight(uv - vec2(0.0, e));
	vec3 n_w = normalize(wnrm - (axis_u * hx + axis_v * hy) * (normal_strength * 0.5 / e));

	// granit benekleri
	float sp = step(0.975, hash12(floor(uv * 320.0))) * speckle_amount;
	float sp2 = step(0.993, hash12(floor(uv * 110.0) + 5.0)) * speckle_amount;

	vec3 col = base_color * (0.8 + 0.5 * fbm(uv * 2.0));
	col += vec3(0.10, 0.105, 0.11) * sp + vec3(0.03) * sp2;

	// asinma / islak parlaklik cizgileri
	float wear = smoothstep(0.55, 0.8, fbm(uv * 1.3 + 71.0)) * wear_amount;
	float rough = rough_base + (fbm(uv * 15.0) - 0.5) * 0.18 - wear * 0.14 - sp * 0.1;

	ALBEDO = col;
	ROUGHNESS = clamp(rough, 0.05, 1.0);
	METALLIC = 0.0;
	SPECULAR = 0.5;
	NORMAL = normalize((VIEW_MATRIX * vec4(n_w, 0.0)).xyz);
}
