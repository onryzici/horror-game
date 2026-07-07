shader_type canvas_item;
// Inceleme modu arka plani: ekrani bulaniklastir + hafif karart + soguk ton.
// Model on planda net dururken dunya "buğulu" kalir (envanter/incele hissi).

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float amount : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 px = SCREEN_PIXEL_SIZE;
	// mipmap tabanli ucuz blur + kucuk cok-tap yumusatma
	vec3 c = textureLod(screen_tex, uv, 3.2).rgb * 0.34;
	c += textureLod(screen_tex, uv + vec2(px.x * 2.5, 0.0), 2.4).rgb * 0.14;
	c += textureLod(screen_tex, uv - vec2(px.x * 2.5, 0.0), 2.4).rgb * 0.14;
	c += textureLod(screen_tex, uv + vec2(0.0, px.y * 2.5), 2.4).rgb * 0.14;
	c += textureLod(screen_tex, uv - vec2(0.0, px.y * 2.5), 2.4).rgb * 0.14;
	c += textureLod(screen_tex, uv, 1.2).rgb * 0.10;
	// karart + hafif soguk ton (odak on plandaki modele kaysin)
	c *= mix(1.0, 0.42, amount);
	c = mix(c, c * vec3(0.82, 0.9, 1.02), amount * 0.5);
	// merkeze dogru cok hafif vinyet
	float vig = smoothstep(1.1, 0.2, distance(uv, vec2(0.5)));
	c *= mix(1.0, 0.7 + 0.3 * vig, amount);
	COLOR = vec4(c, 1.0);
}
