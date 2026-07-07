shader_type spatial;
// Fotogrametri taramasi icin: albedo dokusunu aynen bas, dunya-uzayi
// kutu bolgesindeki fragmanlari at (kapali taranmis kabinin kapi bolgesini
// kesip yerine kendi surgulu panellerimizi koyariz).

uniform sampler2D tex: source_color, filter_linear_mipmap_anisotropic;
uniform vec3 cut_min = vec3(0.0);
uniform vec3 cut_max = vec3(0.0);

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	if (all(greaterThan(world_pos, cut_min)) && all(lessThan(world_pos, cut_max))) {
		discard;
	}
	ALBEDO = texture(tex, UV).rgb;
	ROUGHNESS = 0.88;
	METALLIC = 0.0;
	SPECULAR = 0.25;
}
