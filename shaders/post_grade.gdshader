// Tam ekran post: renk grade (soguk teal), film grain, vinyet,
// kromatik aberasyon, dijital zoom yumusamasi.
shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float grain_amount : hint_range(0.0, 0.3) = 0.075;
uniform float grain_size : hint_range(1.0, 4.0) = 1.6;
uniform float zoom_pixelate : hint_range(0.0, 4.0) = 0.0;
uniform float zoom_grain : hint_range(0.0, 0.2) = 0.0;
uniform vec2 motion_blur = vec2(0.0);
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.34;
uniform float tension_dark : hint_range(0.0, 1.0) = 0.0;
uniform float ca_strength : hint_range(0.0, 3.0) = 0.5;
uniform float saturation : hint_range(0.0, 2.0) = 0.88;
uniform float contrast : hint_range(0.5, 1.5) = 1.06;
uniform float lift = 0.004;
uniform vec3 shadow_tint : source_color = vec3(0.90, 0.99, 1.10);
uniform vec3 highlight_tint : source_color = vec3(0.965, 1.0, 1.01);

float hash13(vec3 p3) {
	p3 = fract(p3 * 0.1031);
	p3 += dot(p3, p3.zyx + 31.32);
	return fract((p3.x + p3.y) * p3.z);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 c = uv - 0.5;
	float r2 = dot(c, c);

	// dijital zoom: gercek sensor kirpma hissi — hafif piksel kuantalama
	vec2 uv_s = uv;
	if (zoom_pixelate > 0.01) {
		vec2 res = 1.0 / SCREEN_PIXEL_SIZE;
		float px = 1.0 + zoom_pixelate;
		uv_s = (floor(uv * res / px) + 0.5) * px / res;
	}
	// kromatik aberasyon (kenara dogru artan, radyal)
	vec2 off = c * r2 * ca_strength * 0.012;
	vec3 col;
	col.r = texture(screen_tex, uv_s + off).r;
	col.g = texture(screen_tex, uv_s).g;
	col.b = texture(screen_tex, uv_s - off).b;

	// donus motion blur: hafif, yonlu (kamera cevrilirken goruntu akar)
	float mbl = length(motion_blur);
	if (mbl > 0.0004) {
		vec3 acc = col;
		acc += texture(screen_tex, uv_s + motion_blur * 0.25).rgb;
		acc += texture(screen_tex, uv_s - motion_blur * 0.25).rgb;
		acc += texture(screen_tex, uv_s + motion_blur * 0.55).rgb;
		acc += texture(screen_tex, uv_s - motion_blur * 0.55).rgb;
		col = acc * 0.2;
	}

	// grade
	float luma = dot(col, vec3(0.2126, 0.7152, 0.0722));
	col = mix(vec3(luma), col, saturation);
	col = (col - 0.5) * contrast + 0.5 + lift;
	vec3 tint = mix(shadow_tint, highlight_tint, smoothstep(0.0, 0.7, luma));
	col *= tint;

	// vinyet
	float vig = 1.0 - vignette_strength * smoothstep(0.08, 0.55, r2);
	// gerilim kararmasi: muzik yogunlasirken kenarlar iceri dogru kapanir
	vig *= 1.0 - tension_dark * smoothstep(0.03, 0.40, r2);
	col *= vig;

	// film grain — luma agirlikli (golgelerde daha cok), her kare yenilenir
	vec2 gcoord = floor(FRAGCOORD.xy / grain_size);
	float t = floor(TIME * 60.0);
	float g = hash13(vec3(gcoord, t)) - 0.5;
	float ga = (grain_amount + zoom_grain) * mix(1.0, 0.3, smoothstep(0.08, 0.85, luma));
	col += g * ga;

	COLOR = vec4(max(col, vec3(0.0)), 1.0);
}
