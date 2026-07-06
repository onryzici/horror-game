// Ruhani golge/hayalet: koyu duman govde, eriyen sacakli kenarlar,
// fresnel ile kaybolan silhouette, hafif soguk kenar parilti.
shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled, unshaded;

uniform float alpha_mul : hint_range(0.0, 1.0) = 1.0;
uniform float phase = 0.0;
// 0 = yirtik seffaf duman, 1 = kesif simsiyah kutle (bulut govde)
uniform float solidity : hint_range(0.0, 1.0) = 0.0;
uniform vec3 core_color : source_color = vec3(0.008, 0.010, 0.016);
uniform vec3 rim_color : source_color = vec3(0.10, 0.16, 0.22);

varying vec3 vpos;

void vertex() {
	// govde boyunca yavas dalgalanma (kumas/duman)
	float hy = clamp(VERTEX.y + 1.0, 0.0, 2.0) * 0.5;
	VERTEX.x += sin(TIME * 2.6 + VERTEX.y * 3.5 + phase) * 0.06 * hy;
	VERTEX.z += cos(TIME * 1.9 + VERTEX.y * 5.0 + phase * 1.7) * 0.045 * hy;
	vpos = VERTEX;
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
		p = p * 2.13 + vec2(19.1);
		a *= 0.5;
	}
	return v;
}

void fragment() {
	float fr = pow(1.0 - clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0), 1.6);
	float ang = atan(vpos.x, vpos.z);
	// yukari akan yirtik duman dokusu
	float n = fbm(vec2(ang * 1.2 + phase, vpos.y * 1.6 - TIME * 1.15));
	float tatters = smoothstep(0.26, 0.62, n + 0.18);
	// altta bacaksiz erime, tepede yumusak kapanis
	float hfade = smoothstep(-0.9, -0.15, vpos.y) * (1.0 - smoothstep(0.72, 1.02, vpos.y));

	float body = mix(tatters, 1.0, solidity);
	float a = alpha_mul * hfade * body * (1.0 - fr * mix(0.9, 0.3, solidity));
	ALBEDO = core_color * (1.0 - solidity * 0.6);
	EMISSION = rim_color * fr * 0.35 * (1.0 - solidity * 0.85);
	ALPHA = clamp(a, 0.0, 1.0);
}
