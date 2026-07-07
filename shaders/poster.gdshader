shader_type spatial;
render_mode cull_disabled;
// Prosedurel vintage metro afisi: yipranmis kagit + retro geometrik grafik +
// leke/su izi/yirtik kose. UV 0..1 (QuadMesh). Her afis seed+renk+layout ile
// farkli okunur. Amac: duz renk kutu degil, "eski asilmis afis" hissi.

uniform vec3 ink_a : source_color = vec3(0.72, 0.24, 0.18);   // ana grafik
uniform vec3 ink_b : source_color = vec3(0.14, 0.22, 0.30);   // aksan
uniform vec3 paper : source_color = vec3(0.80, 0.75, 0.62);   // kagit
uniform int layout = 0;         // 0 gunes/kavis, 1 diyagonal bant, 2 blok, 3 hedef
uniform float seed = 0.0;
uniform float wear : hint_range(0.0, 1.0) = 0.55;   // yipranma miktari

float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}
float vnoise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	float a = hash12(i), b = hash12(i + vec2(1, 0));
	float c = hash12(i + vec2(0, 1)), d = hash12(i + vec2(1, 1));
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}
float fbm(vec2 p) {
	float v = 0.0, a = 0.5;
	for (int i = 0; i < 5; i++) { v += a * vnoise(p); p = p * 2.13 + vec2(19.1); a *= 0.5; }
	return v;
}

void fragment() {
	vec2 uv = UV;
	vec2 s = vec2(seed * 3.7, seed * 1.9);

	// --- kagit zemin: sararma + lifli doku + foxing (kahverengi benekler) ---
	vec3 col = paper;
	col *= 0.86 + 0.20 * fbm(uv * 5.0 + s);                    // ton dalgalanmasi
	col *= 1.0 - 0.10 * fbm(uv * vec2(2.0, 60.0) + s);         // dusey kagit lifi
	float fox = smoothstep(0.62, 0.78, fbm(uv * 9.0 + s * 2.0));
	col = mix(col, col * vec3(0.72, 0.60, 0.42), fox * 0.5);   // sari-kahve benek

	// --- retro grafik kompozisyonu (ust ~%70) ---
	float ink = 0.0;              // ana murekkep maskesi
	float ink2 = 0.0;             // aksan
	vec2 g = uv;
	if (layout == 0) {
		// yukselen gunes: kavisli isinlar + yatay ufuk cizgileri
		vec2 c = vec2(0.5, 0.30);
		float r = length((g - c) * vec2(1.0, 1.35));
		ink += smoothstep(0.30, 0.28, r);                     // disk
		float ang = atan(g.y - c.y, g.x - c.x);
		float rays = smoothstep(0.5, 0.9, sin(ang * 14.0)) * smoothstep(0.62, 0.30, r);
		ink2 += rays * step(c.y, g.y + 0.02);
		for (int i = 0; i < 4; i++) {
			float yy = 0.60 + float(i) * 0.052;
			ink2 += smoothstep(0.010, 0.004, abs(g.y - yy)) * (1.0 - float(i) * 0.2);
		}
	} else if (layout == 1) {
		// art-deco diyagonal bantlar
		float d = g.x * 0.7 + g.y;
		ink += smoothstep(0.45, 0.44, abs(fract(d * 3.0) - 0.5));
		ink2 += smoothstep(0.03, 0.02, abs(fract(d * 3.0 + 0.5) - 0.5)) * 0.8;
		ink *= step(g.y, 0.72);
		ink2 *= step(g.y, 0.72);
	} else if (layout == 2) {
		// stilize tren/blok siluet + pencere sirasi
		float body = step(0.18, g.x) * step(g.x, 0.82)
				* step(0.34, g.y) * step(g.y, 0.60);
		ink += body;
		float win = step(0.24, g.x) * step(g.x, 0.76)
				* step(0.44, g.y) * step(g.y, 0.54)
				* step(0.4, fract(g.x * 9.0));
		ink2 += win * body;
		ink += step(0.30, g.x) * step(g.x, 0.70) * step(0.60, g.y) * step(g.y, 0.635);
	} else {
		// konsantrik hedef (tunel agzi)
		float r = length((g - vec2(0.5, 0.36)) * vec2(1.0, 1.2));
		ink += smoothstep(0.5, 0.48, abs(fract(r * 6.0) - 0.25));
		ink2 += smoothstep(0.03, 0.0, r) ;
		ink *= smoothstep(0.42, 0.40, r);
	}
	ink = clamp(ink, 0.0, 1.0);
	ink2 = clamp(ink2, 0.0, 1.0);

	// alt bant (baslik zemini) — koyu murekkep serit
	float band = step(0.80, uv.y);
	ink2 = max(ink2, band);

	// murekkep kagida basilir (hafif solmus); baski kenarlari duzensiz
	float edge = 0.9 + 0.1 * fbm(uv * 40.0 + s);
	col = mix(col, ink_a, ink * 0.88 * edge);
	col = mix(col, ink_b, ink2 * 0.85 * edge);

	// --- yipranma katmani ---
	// su lekesi: buyuk yumusak koyu-kenarli halkalar
	float stain = fbm(uv * 3.0 + s * 3.0);
	float ring = smoothstep(0.48, 0.52, stain) * smoothstep(0.62, 0.55, stain);
	col = mix(col, col * vec3(0.62, 0.56, 0.44), ring * wear * 0.8);
	// soyulma/yirtik: ust ve kose bolgelerde kagit kalkmis (acik leke)
	float tear = smoothstep(0.55, 0.75, fbm(uv * 6.0 + s * 5.0 + 10.0));
	float corner = smoothstep(0.7, 1.0, length(uv - vec2(0.92, 0.08)) * 1.4)
			+ smoothstep(0.7, 1.0, length(uv - vec2(0.06, 0.94)) * 1.4);
	float peel = clamp(tear * corner, 0.0, 1.0) * wear;
	col = mix(col, paper * 1.08, peel * 0.7);
	// ince cizik/katlanma
	col *= 1.0 - 0.12 * wear * smoothstep(0.7, 0.72, fbm(uv * vec2(80.0, 3.0) + s));
	// kenar/kose kararmasi (vinyet — eski kagit)
	float vig = smoothstep(0.0, 0.35, uv.x) * smoothstep(1.0, 0.65, uv.x)
			* smoothstep(0.0, 0.30, uv.y) * smoothstep(1.0, 0.70, uv.y);
	col *= mix(1.0, 0.80, (1.0 - vig) * (0.4 + 0.6 * wear));
	// genel kir
	col *= 0.94 + 0.06 * fbm(uv * 22.0 + s);

	ALBEDO = col;
	ROUGHNESS = 0.92;
	METALLIC = 0.0;
	SPECULAR = 0.15;
}
