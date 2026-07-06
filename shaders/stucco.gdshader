// Puskurtme siva (puturlu tavan/duvar) — iri taneli, lekeli, gercekci.
// Katmanlar: iri lekeler + orta grit + puskurtme tepecikleri + koyu gozenekler.
shader_type spatial;
render_mode cull_back;

uniform vec3 base_color : source_color = vec3(0.62, 0.635, 0.63);
uniform float blob_scale = 9.0;
uniform float grit_scale = 55.0;
uniform float bump_amp = 0.0045;
uniform float rough_base : hint_range(0.0, 1.0) = 0.95;
uniform float mottle : hint_range(0.0, 1.0) = 0.35;
uniform float dirt_amount : hint_range(0.0, 1.0) = 0.35;
uniform float normal_strength : hint_range(0.0, 3.0) = 1.4;

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
	for (int i = 0; i < 4; i++) {
		v += a * vnoise(p);
		p = p * 2.17 + vec2(31.3);
		a *= 0.5;
	}
	return v;
}

float sheight(vec2 uv) {
	float blobs = fbm(uv * blob_scale);
	float grit = fbm(uv * grit_scale);
	// puskurtme tepecikleri: seyrek, sivri
	float spikes = smoothstep(0.60, 0.95, vnoise(uv * grit_scale * 1.7 + 7.0));
	return (blobs * 0.50 + grit * 0.35 + spikes * 0.45) * bump_amp;
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

	float e = 0.006;
	float h0 = sheight(uv);
	float hx = sheight(uv + vec2(e, 0.0)) - sheight(uv - vec2(e, 0.0));
	float hy = sheight(uv + vec2(0.0, e)) - sheight(uv - vec2(0.0, e));
	vec3 n_w = normalize(wnrm - (axis_u * hx + axis_v * hy) * (normal_strength * 0.5 / e));

	// buyuk olcek ton dalgalanmasi + leke (mottle)
	float shade = 0.88 + 0.24 * fbm(uv * 2.1);
	float stain = smoothstep(0.55, 0.85, fbm(uv * blob_scale * 0.7 + 31.0));
	vec3 col = base_color * shade * (1.0 - mottle * 0.4 * stain);

	// koyu gozenekler (sivanin icindeki delikler)
	float pore = step(0.94, hash12(floor(uv * grit_scale * 3.0)));
	col *= 1.0 - pore * 0.18;

	// genel kir
	float dirt = dirt_amount * fbm(uv * 0.55 + 53.0) * 0.5;
	col *= 1.0 - dirt;

	// yukseklikten sahte AO: cukurlar koyu
	float ao = mix(0.72, 1.0, clamp(h0 / max(bump_amp, 1e-5), 0.0, 1.0));

	ALBEDO = col;
	ROUGHNESS = clamp(rough_base + (fbm(uv * 14.0) - 0.5) * 0.08, 0.0, 1.0);
	METALLIC = 0.0;
	SPECULAR = 0.25;
	AO = ao;
	AO_LIGHT_AFFECT = 0.35;
	NORMAL = normalize((VIEW_MATRIX * vec4(n_w, 0.0)).xyz);
}
