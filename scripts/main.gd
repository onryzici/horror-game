extends Node3D
## SON SEFER — Hisar-7 UST PERON (CLAUDE.md Bolum 1 mekani).
## Metro peronu: ray cukuru + tunel agizlari + kolonlar + banklar + istasyon
## tabelasi + sigorta panosu + bozuk saat + poster ve isik sirasi (biri bozuk).
## Perondan yukari cikan duz, genis merdiven (8 basamak + duzluk + 12 basamak)
## karanlik bir ust kata gider. Fotorealistik: prosedurel fayans/siva, SDFGI,
## SSR, volumetrik sis, film grain. Muzik: "Horror Atmosphere" (CC0, J. Junkala).

# ---- merdiven olculeri ----
const W := 6.0
const HW := W * 0.5
const RISE := 0.155
const RUN := 0.30
const STEPS1 := 8
const STEPS2 := 12
const F1_RISE := STEPS1 * RISE          # 1.24
const LAND_Z0 := -(STEPS1 * RUN)        # -2.4
const LAND_Z1 := LAND_Z0 - 2.0          # -4.4
const F2_END_Z := LAND_Z1 - STEPS2 * RUN  # -8.0
const TOP_Y := F1_RISE + STEPS2 * RISE  # 3.10
const STAIR_END_Z := -10.6              # ust koridorun karanlik sonu

# ---- peron olculeri ----
const PLAT_L := 15.0                    # peron yari uzunlugu (x: -15..15)
const PLAT_D := 7.6                     # peron derinligi (z: 0..7.6)
const PIT_Z0 := PLAT_D                  # ray cukuru basi
const PIT_Z1 := 11.5                    # karsi duvar
const PIT_Y := -1.3                     # cukur tabani
const CEIL_Y := 3.5                     # peron tavani

var mat_white_tile: ShaderMaterial
var mat_marble_tile: ShaderMaterial
var mat_dark_tile: ShaderMaterial
var mat_floor_tile: ShaderMaterial
var mat_plat_floor: ShaderMaterial
var mat_stucco: ShaderMaterial
var mat_soffit: ShaderMaterial
var mat_stone: ShaderMaterial
var mat_concrete: ShaderMaterial
var mat_tactile: ShaderMaterial
var mat_metal: StandardMaterial3D
var mat_steel_rail: StandardMaterial3D
var mat_pipe: StandardMaterial3D
var mat_paint: StandardMaterial3D
var mat_nosing: StandardMaterial3D
var mat_void: StandardMaterial3D
var mat_navy: StandardMaterial3D

var _lamp_scene: PackedScene
var _norm_fine: NoiseTexture2D
var _norm_coarse: NoiseTexture2D
var _buzz_stream: AudioStreamWAV


## Prosedurel detay normal haritasi (duz malzemeler "ucuz CGI" gorunmesin)
func _mk_norm(freq: float, strength: float) -> NoiseTexture2D:
	var n := FastNoiseLite.new()
	n.seed = 42
	n.frequency = freq
	n.fractal_octaves = 4
	var t := NoiseTexture2D.new()
	t.width = 256
	t.height = 256
	t.seamless = true
	t.as_normal_map = true
	t.bump_strength = strength
	t.noise = n
	return t


## Malzemeye mikro-yuzey detayi ekle (uv_y > 0 ise gerilmis/fircalanmis doku)
func _detail(m: StandardMaterial3D, uv: float, ns: float, coarse := false,
		uv_y := -1.0) -> StandardMaterial3D:
	m.normal_enabled = true
	m.normal_texture = _norm_coarse if coarse else _norm_fine
	m.normal_scale = ns
	m.uv1_scale = Vector3(uv, uv_y if uv_y > 0.0 else uv, uv)
	return m


## Floresan cizirti sesi (sentez: 100 Hz sebeke viziltisi + citirti)
func _make_buzz() -> AudioStreamWAV:
	var rate := 22050
	var n := rate * 2
	var data := PackedByteArray()
	data.resize(n * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in n:
		var t := float(i) / float(rate)
		var v := 0.30 * sin(TAU * 100.0 * t)
		v += 0.16 * sin(TAU * 200.0 * t + 0.7)
		v += 0.10 * signf(sin(TAU * 100.0 * t)) * (0.5 + 0.5 * sin(TAU * 2.3 * t))
		v += rng.randf_range(-0.14, 0.14) * (0.35 + 0.65 * absf(sin(TAU * 0.41 * t)))
		data.encode_s16(i * 2, int(clampf(v * 0.4, -1.0, 1.0) * 32767.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.stereo = false
	w.data = data
	w.loop_mode = AudioStreamWAV.LOOP_FORWARD
	w.loop_end = n
	return w


## Bolgeye girince tetiklenen korku sesi (sogutmali, konumsal)
func _trigger_sound(pos: Vector3, size: Vector3, stream: AudioStream,
		vol_db: float, pitch: float, cooldown: float) -> void:
	var area := Area3D.new()
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	cs.shape = bs
	area.add_child(cs)
	area.position = pos
	var sp := AudioStreamPlayer3D.new()
	sp.stream = stream
	sp.volume_db = vol_db
	sp.pitch_scale = pitch
	sp.max_distance = 30.0
	area.add_child(sp)
	area.set_meta("last_t", -1e9)
	area.body_entered.connect(func(body: Node3D) -> void:
		if body is CharacterBody3D:
			var now := Time.get_ticks_msec() / 1000.0
			if now - float(area.get_meta("last_t")) > cooldown:
				area.set_meta("last_t", now)
				sp.play()
	)
	add_child(area)


func _ready() -> void:
	_lamp_scene = load("res://models/weathered_fluorescent_lightlamp.glb")
	_make_materials()
	_build_stairwell()
	_build_platform()
	_build_props()
	_build_rails()
	_build_lights()
	_build_environment()
	_build_audio()
	_build_post_fx()
	_spawn_player()
	_maybe_screenshot()


# ------------------------------------------------------------------ malzemeler

func _tile_mat(size: float, tcol: Color, gcol: Color, rough: float,
		variation: float, tilt: float, streak: float, dirt: float,
		grout_w := 0.006) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = load("res://shaders/tiles.gdshader")
	m.set_shader_parameter("tile_size", size)
	m.set_shader_parameter("tile_color", Vector3(tcol.r, tcol.g, tcol.b))
	m.set_shader_parameter("grout_color", Vector3(gcol.r, gcol.g, gcol.b))
	m.set_shader_parameter("tile_roughness", rough)
	m.set_shader_parameter("color_variation", variation)
	m.set_shader_parameter("tilt_variation", tilt)
	m.set_shader_parameter("streak_amount", streak)
	m.set_shader_parameter("dirt_amount", dirt)
	m.set_shader_parameter("grout_width", grout_w)
	return m


func _make_materials() -> void:
	_norm_fine = _mk_norm(0.08, 5.0)
	_norm_coarse = _mk_norm(0.025, 10.0)
	mat_white_tile = _tile_mat(0.098, Color(0.84, 0.855, 0.85), Color(0.20, 0.22, 0.24),
			0.15, 0.35, 0.6, 0.12, 1.0, 0.005)
	mat_marble_tile = _tile_mat(0.15, Color(0.83, 0.845, 0.84), Color(0.22, 0.24, 0.25),
			0.11, 0.45, 0.5, 0.55, 0.9, 0.004)
	mat_dark_tile = _tile_mat(0.20, Color(0.10, 0.125, 0.15), Color(0.05, 0.06, 0.07),
			0.15, 0.5, 0.8, 0.25, 1.2, 0.007)
	mat_floor_tile = _tile_mat(0.33, Color(0.48, 0.50, 0.50), Color(0.16, 0.17, 0.18),
			0.26, 0.4, 0.5, 0.2, 1.4, 0.008)
	mat_plat_floor = _tile_mat(0.4, Color(0.44, 0.46, 0.46), Color(0.15, 0.16, 0.17),
			0.3, 0.45, 0.5, 0.2, 1.6, 0.01)

	mat_stucco = ShaderMaterial.new()
	mat_stucco.shader = load("res://shaders/stucco.gdshader")

	mat_soffit = ShaderMaterial.new()
	mat_soffit.shader = load("res://shaders/stucco.gdshader")
	mat_soffit.set_shader_parameter("base_color", Vector3(0.30, 0.315, 0.315))
	mat_soffit.set_shader_parameter("bump_amp", 0.007)
	mat_soffit.set_shader_parameter("grit_scale", 40.0)
	mat_soffit.set_shader_parameter("mottle", 0.5)
	mat_soffit.set_shader_parameter("dirt_amount", 0.55)

	mat_stone = ShaderMaterial.new()
	mat_stone.shader = load("res://shaders/stone.gdshader")

	# ray cukuru / tunel betonu: koyu, mat, kirli
	mat_concrete = ShaderMaterial.new()
	mat_concrete.shader = load("res://shaders/stucco.gdshader")
	mat_concrete.set_shader_parameter("base_color", Vector3(0.17, 0.18, 0.18))
	mat_concrete.set_shader_parameter("bump_amp", 0.004)
	mat_concrete.set_shader_parameter("grit_scale", 24.0)
	mat_concrete.set_shader_parameter("mottle", 0.6)
	mat_concrete.set_shader_parameter("dirt_amount", 0.8)
	mat_concrete.set_shader_parameter("rough_base", 0.97)

	mat_tactile = ShaderMaterial.new()
	mat_tactile.shader = load("res://shaders/tactile.gdshader")

	mat_metal = StandardMaterial3D.new()
	mat_metal.albedo_color = Color(0.9, 0.92, 0.94)
	mat_metal.metallic = 1.0
	mat_metal.roughness = 0.13
	_detail(mat_metal, 5.0, 0.1)

	mat_steel_rail = StandardMaterial3D.new()
	mat_steel_rail.albedo_color = Color(0.75, 0.76, 0.78)
	mat_steel_rail.metallic = 1.0
	mat_steel_rail.roughness = 0.32
	_detail(mat_steel_rail, 4.0, 0.2)

	mat_pipe = StandardMaterial3D.new()
	mat_pipe.albedo_color = Color(0.68, 0.69, 0.68)
	mat_pipe.metallic = 0.15
	mat_pipe.roughness = 0.45
	_detail(mat_pipe, 3.0, 0.35)

	# boyali beton: portakal kabugu dokusu
	mat_paint = StandardMaterial3D.new()
	mat_paint.albedo_color = Color(0.70, 0.72, 0.71)
	mat_paint.roughness = 0.4
	_detail(mat_paint, 2.0, 0.5, true)

	mat_nosing = StandardMaterial3D.new()
	mat_nosing.albedo_color = Color(0.30, 0.31, 0.31)
	mat_nosing.roughness = 0.6
	_detail(mat_nosing, 3.0, 0.4)

	mat_void = StandardMaterial3D.new()
	mat_void.albedo_color = Color(0.005, 0.006, 0.008)
	mat_void.roughness = 1.0

	mat_navy = StandardMaterial3D.new()
	mat_navy.albedo_color = Color(0.07, 0.10, 0.18)
	mat_navy.roughness = 0.35
	_detail(mat_navy, 2.5, 0.25)


# ------------------------------------------------------------------ yardimcilar

func _box(size: Vector3, pos: Vector3, mat: Material, collide := true) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	add_child(mi)
	if collide:
		var sb := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = size
		cs.shape = bs
		sb.add_child(cs)
		mi.add_child(sb)
	return mi


static func _basis_from_y(y: Vector3) -> Basis:
	var helper := Vector3.UP if absf(y.dot(Vector3.UP)) < 0.99 else Vector3(1, 0, 0)
	var x := helper.cross(y).normalized()
	return Basis(x, y, x.cross(y))


func _tube(a: Vector3, b: Vector3, radius: float, mat: Material) -> MeshInstance3D:
	var d := b - a
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.height = d.length()
	cm.top_radius = radius
	cm.bottom_radius = radius
	cm.radial_segments = 24
	mi.mesh = cm
	mi.material_override = mat
	mi.transform = Transform3D(_basis_from_y(d.normalized()), (a + b) * 0.5)
	add_child(mi)
	return mi


func _ball(pos: Vector3, radius: float, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = radius
	sm.height = radius * 2.0
	mi.mesh = sm
	mi.material_override = mat
	mi.position = pos
	add_child(mi)


## a->b dogrultusunda egik levha; alt yuzu a-b cizgisine oturur.
func _slab(a: Vector3, b: Vector3, width: float, thickness: float, mat: Material,
		collide := false) -> void:
	var d := b - a
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(width, thickness, d.length())
	mi.mesh = bm
	mi.material_override = mat
	var bas := Basis.looking_at(d.normalized(), Vector3.UP)
	mi.transform = Transform3D(bas, (a + b) * 0.5 + bas.y * (thickness * 0.5))
	add_child(mi)
	if collide:
		var sb := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = bm.size
		cs.shape = bs
		sb.add_child(cs)
		mi.add_child(sb)


func _ramp_collider(a: Vector3, b: Vector3, width: float) -> void:
	var d := b - a
	var sb := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(width, 0.2, d.length())
	cs.shape = bs
	var bas := Basis.looking_at(d.normalized(), Vector3.UP)
	sb.transform = Transform3D(bas, (a + b) * 0.5 - bas.y * 0.1)
	sb.add_child(cs)
	add_child(sb)


## merdiven burun cizgisi
func _nose_y(z: float) -> float:
	if z >= 0.0:
		return 0.0
	if z >= LAND_Z0:
		return -z / RUN * RISE
	if z >= LAND_Z1:
		return F1_RISE
	if z >= F2_END_Z:
		return F1_RISE + (LAND_Z1 - z) / RUN * RISE
	return TOP_Y


func _flight(z_start: float, y_start: float, steps: int, width: float, cx: float) -> void:
	for i in steps:
		var top_y := y_start + (i + 1) * RISE
		var z0 := z_start - i * RUN
		_box(Vector3(width, RISE + 0.06, RUN + 0.02),
				Vector3(cx, top_y - (RISE + 0.06) * 0.5, z0 - RUN * 0.5), mat_stone, false)
		_box(Vector3(width, 0.008, 0.05),
				Vector3(cx, top_y + 0.002, z0 - 0.032), mat_nosing, false)
	_ramp_collider(Vector3(cx, y_start, z_start),
			Vector3(cx, y_start + steps * RISE, z_start - steps * RUN), width)


## beyaz fayans duvar + koyu supurgelik bandi (duvarla ayni hizada, tasma yok)
func _tiled_wall(size: Vector3, pos: Vector3, mat: Material, skirt_face_z: float) -> void:
	_box(size, pos, mat)
	# supurgelik: duvar yuzeyinden 1 cm tasan ince koyu bant
	_box(Vector3(size.x, 0.36, 0.012),
			Vector3(pos.x, pos.y - size.y * 0.5 + 0.18 + 0.3, skirt_face_z + 0.005),
			mat_dark_tile, false)


# ------------------------------------------------------------------ merdiven kovasi

func _build_stairwell() -> void:
	var wall_h := 6.6
	var wall_cy := wall_h * 0.5 - 0.3

	# zeminler
	_box(Vector3(W, 0.3, LAND_Z0 - LAND_Z1),
			Vector3(0, F1_RISE - 0.15, (LAND_Z0 + LAND_Z1) * 0.5), mat_floor_tile)
	_box(Vector3(W, 0.3, F2_END_Z - STAIR_END_Z),
			Vector3(0, TOP_Y - 0.15, (F2_END_Z + STAIR_END_Z) * 0.5), mat_stone)

	_flight(0.0, 0.0, STEPS1, W, 0.0)
	_flight(LAND_Z1, F1_RISE, STEPS2, W, 0.0)

	# bantlar
	_box(Vector3(W - 0.4, 0.012, 0.4), Vector3(0, 0.006, 0.55), mat_tactile, false)
	_box(Vector3(W - 0.4, 0.012, 0.4),
			Vector3(0, F1_RISE + 0.006, LAND_Z0 - 0.4), mat_tactile, false)
	_box(Vector3(W - 0.4, 0.012, 0.4),
			Vector3(0, F1_RISE + 0.006, LAND_Z1 + 0.4), mat_tactile, false)

	# yan duvarlar: peron arka duvariyla cakismasin diye z=-0.1'de biter
	# (kose kaplamasini stair agzi kolonlari yapar — es duzlem yok, oynama yok)
	_box(Vector3(0.3, wall_h, -STAIR_END_Z + 0.2 - 0.1),
			Vector3(-HW - 0.15, wall_cy, (STAIR_END_Z - 0.2 - 0.1) * 0.5), mat_white_tile)
	_box(Vector3(0.3, wall_h, -STAIR_END_Z + 0.2 - 0.1),
			Vector3(HW + 0.15, wall_cy, (STAIR_END_Z - 0.2 - 0.1) * 0.5), mat_marble_tile)
	# merdiven agzi kose kolonlari (pilaster): tum birlesim yerlerini kapatir
	for side in [-1.0, 1.0]:
		_box(Vector3(0.44, wall_h, 0.44), Vector3(side * (HW + 0.08), wall_cy, -0.08),
				mat_marble_tile)
		_box(Vector3(0.47, 0.36, 0.47), Vector3(side * (HW + 0.08), 0.18, -0.08),
				mat_dark_tile, false)
	# ust kat sonu: karanlik
	_box(Vector3(W + 1.0, wall_h, 0.3), Vector3(0, wall_cy, STAIR_END_Z - 0.15), mat_void)

	# tavanlar: DUZ ve FERAH — egim yok, iki yuksek kademe + boyali gecis bantlari
	_box(Vector3(W + 0.6, 0.3, 1.35), Vector3(0, CEIL_Y + 0.14, -0.55), mat_stucco, false)
	# agiz gecis bandi (peron 3.5 -> merdiven 4.35)
	_box(Vector3(W + 0.6, 1.06, 0.15), Vector3(0, 3.92, -1.13), mat_paint, false)
	# 1. kademe: alt kol + duzluk uzeri duz tavan (4.35)
	_box(Vector3(W + 0.6, 0.3, 3.25), Vector3(0, 4.5, -2.82), mat_stucco, false)
	# 2. gecis bandi (4.35 -> 5.75)
	_box(Vector3(W + 0.6, 1.55, 0.15), Vector3(0, 5.08, -4.47), mat_paint, false)
	# 2. kademe: ust kol uzeri duz tavan (5.75) — gecis bandindan son duvara kadar
	# kesintisiz (arada bosluk kalmasin)
	_box(Vector3(W + 0.6, 0.3, 6.4),
			Vector3(0, 5.9, -7.62), mat_stucco, false)


# ------------------------------------------------------------------ peron

func _build_platform() -> void:
	var wall_h := 4.2
	var wall_cy := wall_h * 0.5 - 0.3

	# peron zemini
	_box(Vector3(PLAT_L * 2.0, 0.3, PLAT_D), Vector3(0, -0.15, PLAT_D * 0.5), mat_plat_floor)
	# peron kenari sari bant
	_box(Vector3(PLAT_L * 2.0 - 0.4, 0.012, 0.42),
			Vector3(0, 0.006, PLAT_D - 0.45), mat_tactile, false)
	# kenar beyaz cizgi
	_box(Vector3(PLAT_L * 2.0 - 0.4, 0.01, 0.1),
			Vector3(0, 0.005, PLAT_D - 0.12), mat_paint, false)

	# ray cukuru
	_box(Vector3(PLAT_L * 2.0 + 1.2, 1.05, 0.22),
			Vector3(0, PIT_Y * 0.5 - 0.12, PIT_Z0 + 0.11), mat_concrete)  # peron alti yuz
	_box(Vector3(PLAT_L * 2.0 + 1.2, 0.25, PIT_Z1 - PIT_Z0),
			Vector3(0, PIT_Y - 0.125, (PIT_Z0 + PIT_Z1) * 0.5), mat_concrete)  # cukur tabani
	# karsi duvar (tunel duvari)
	_box(Vector3(PLAT_L * 2.0 + 1.2, 5.2, 0.3),
			Vector3(0, PIT_Y + 2.6 - 0.2, PIT_Z1 + 0.15), mat_white_tile)

	# raylar + traversler
	for rz in [PIT_Z0 + 0.95, PIT_Z0 + 2.35]:
		_box(Vector3(PLAT_L * 2.0 + 1.4, 0.14, 0.07),
				Vector3(0, PIT_Y + 0.07, rz), mat_steel_rail, false)
	var nties := int((PLAT_L * 2.0 + 1.2) / 0.75)
	for i in nties:
		var tx := -PLAT_L - 0.5 + i * 0.75
		_box(Vector3(0.24, 0.1, 2.2),
				Vector3(tx, PIT_Y - 0.05, (PIT_Z0 + PIT_Z1) * 0.5 - 0.1), mat_void, false)

	# peron arka duvarlari (merdiven agzinin iki yani; kose kolonuna kadar)
	_tiled_wall(Vector3(PLAT_L - HW - 0.28, wall_h, 0.3),
			Vector3(-(PLAT_L + HW + 0.28) * 0.5, wall_cy, -0.15), mat_marble_tile, 0.0)
	_tiled_wall(Vector3(PLAT_L - HW - 0.28, wall_h, 0.3),
			Vector3((PLAT_L + HW + 0.28) * 0.5, wall_cy, -0.15), mat_marble_tile, 0.0)

	# peron uc duvarlari
	_box(Vector3(0.3, wall_h, PLAT_D + 0.6),
			Vector3(-PLAT_L - 0.15, wall_cy, PLAT_D * 0.5 - 0.15), mat_white_tile)
	_box(Vector3(0.3, wall_h, PLAT_D + 0.6),
			Vector3(PLAT_L + 0.15, wall_cy, PLAT_D * 0.5 - 0.15), mat_white_tile)

	# tunel agizlari: ray koridoru karanliga devam eder
	for sx in [-1.0, 1.0]:
		# portal lentosu
		_box(Vector3(0.5, 1.3, PIT_Z1 - PIT_Z0 + 0.6),
				Vector3(sx * (PLAT_L - 1.2), CEIL_Y - 0.55, (PIT_Z0 + PIT_Z1) * 0.5),
				mat_concrete, false)
		# tunel ici karanlik kapak
		_box(Vector3(0.3, 6.0, PIT_Z1 - PIT_Z0 + 1.0),
				Vector3(sx * (PLAT_L + 2.2), 1.2, (PIT_Z0 + PIT_Z1) * 0.5), mat_void, false)

	# peron tavani (ray ustu dahil)
	_box(Vector3(PLAT_L * 2.0 + 1.2, 0.3, PIT_Z1 + 0.6),
			Vector3(0, CEIL_Y + 0.15, (PIT_Z1 + 0.6) * 0.5 - 0.3), mat_stucco, false)

	# kolonlar (fayansli, kare; taban bandi hafif ve duzgun)
	for cxp in [-12.0, -7.5, 4.5, 9.0, 13.5]:
		_box(Vector3(0.55, CEIL_Y, 0.55), Vector3(cxp, CEIL_Y * 0.5, 5.4), mat_marble_tile)
		_box(Vector3(0.575, 0.36, 0.575), Vector3(cxp, 0.18, 5.4), mat_dark_tile, false)

	# tavan borulari: gercek boru kiti (pipe_set.glb) — parca parca dosenir
	_pipe_run(Vector3(-15.5, CEIL_Y - 0.16, 1.0), Vector3(15.5, CEIL_Y - 0.16, 1.0),
			0.0063, {5: "Valve", 27: "Valve"})
	_pipe_run(Vector3(-15.5, CEIL_Y - 0.1, 1.35), Vector3(15.5, CEIL_Y - 0.1, 1.35), 0.0042)
	for i in 8:
		var hx := -14.0 + i * 4.0
		_tube(Vector3(hx, CEIL_Y - 0.16, 1.0), Vector3(hx, CEIL_Y + 0.05, 1.0), 0.012, mat_pipe)


# ------------------------------------------------------------------ dekor / oyun nesneleri

var _pipe_parts := {}  # parca adi -> [Mesh, AABB(kok uzayi), Transform3D(kok uzayi)]

func _load_pipe_parts() -> void:
	if not _pipe_parts.is_empty():
		return
	var ps: PackedScene = load("res://assets/models/pipe_set/pipe_set.glb")
	if ps == null:
		return
	var src: Node3D = ps.instantiate()
	var found: Array = []
	_collect_meshes(src, Transform3D.IDENTITY, "", found)
	for f in found:
		var mi: MeshInstance3D = f[0]
		var xf: Transform3D = f[1]
		var key := String(mi.name).split("_")[0]
		_pipe_parts[key] = [mi.mesh, xf * mi.get_aabb(), xf]
	src.queue_free()


## Gercek boru kiti dosemesi: a->b arasi UNIFORM olcekli parcalar uc uca eklenir
## (model esnetilmez; son parca duvara gomulerek biter). specials: {indeks: "Valve"}.
func _pipe_run(a: Vector3, b: Vector3, s: float, specials := {}) -> void:
	_load_pipe_parts()
	if not _pipe_parts.has("Normal"):
		return
	var dir := (b - a).normalized()
	var total := a.distance_to(b)
	var bas := _basis_from_y(dir)
	var cursor := 0.0
	var idx := 0
	while cursor < total:
		var key: String = specials.get(idx, "Normal")
		if not _pipe_parts.has(key):
			key = "Normal"
		var part: Array = _pipe_parts[key]
		var aabb: AABB = part[1]
		var holder := Node3D.new()
		holder.transform = Transform3D(bas, a + dir * cursor)
		var mi := MeshInstance3D.new()
		mi.mesh = part[0]
		var c := aabb.get_center()
		var off := Vector3(-c.x, -aabb.position.y, -c.z) * s
		mi.transform = Transform3D(Basis.from_scale(Vector3.ONE * s), off) * part[2]
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		holder.add_child(mi)
		add_child(holder)
		cursor += aabb.size.y * s
		idx += 1


## GLB kit icinden isim onekiyle parca sec, duvara monte et.
## Kit uzayinda: X = derinlik (sirt x-min'de), Y = yukseklik, Z = genislik.
## pos = montaj noktasi (sirt yuzeyin ortasi); yaw ile on yuz yonlendirilir.
func _prop_named(path: String, prefix: String, pos: Vector3, yaw_deg: float) -> Node3D:
	var ps: PackedScene = load(path)
	if ps == null:
		return null
	var src: Node3D = ps.instantiate()
	var found: Array = []  # [MeshInstance3D, Transform3D]
	_collect_meshes(src, Transform3D.IDENTITY, prefix, found)
	if found.is_empty():
		src.queue_free()
		return null
	var aabb: AABB = found[0][1] * (found[0][0] as MeshInstance3D).get_aabb()
	for i in range(1, found.size()):
		aabb = aabb.merge(found[i][1] * (found[i][0] as MeshInstance3D).get_aabb())
	var holder := Node3D.new()
	holder.position = pos
	holder.rotation.y = deg_to_rad(yaw_deg)
	var inner := Node3D.new()
	var c := aabb.get_center()
	inner.position = Vector3(-aabb.position.x, -c.y, -c.z)
	holder.add_child(inner)
	for f in found:
		var dup: MeshInstance3D = (f[0] as MeshInstance3D).duplicate()
		dup.transform = f[1]
		inner.add_child(dup)
	src.queue_free()
	add_child(holder)
	return holder


func _collect_meshes(node: Node, xf: Transform3D, prefix: String, out: Array) -> void:
	var local_xf := xf
	if node is Node3D:
		local_xf = xf * (node as Node3D).transform
	if node is MeshInstance3D and node.name.begins_with(prefix):
		out.append([node, local_xf])
	for ch in node.get_children():
		_collect_meshes(ch, local_xf, prefix, out)


## Indirilen GLTF modeli yukle, olcekle, yere oturt.
func _prop(path: String, pos: Vector3, yaw_deg: float, target: float,
		floor_sit := true) -> Node3D:
	var ps: PackedScene = load(path)
	if ps == null:
		return null
	var n: Node3D = ps.instantiate()
	var holder := Node3D.new()
	holder.position = pos
	holder.rotation.y = deg_to_rad(yaw_deg)
	var res := _calc_aabb(n, Transform3D.IDENTITY)
	if res[1]:
		var aabb: AABB = res[0]
		var longest := maxf(aabb.size.x, maxf(aabb.size.y, aabb.size.z))
		var s := target / maxf(longest, 0.001)
		n.scale = Vector3.ONE * s
		var off := -aabb.get_center() * s
		if floor_sit:
			off.y = -aabb.position.y * s
		n.position = off
	holder.add_child(n)
	add_child(holder)
	return holder


## Metro bank: celik ayaklar + citali ahsap oturak/sirtlik (duvara dayali)
func _bench(x: float) -> void:
	var z := 0.46
	var steel := StandardMaterial3D.new()
	steel.albedo_color = Color(0.22, 0.23, 0.25)
	steel.metallic = 0.85
	steel.roughness = 0.38
	for sx in [x - 0.82, x + 0.82]:
		_box(Vector3(0.05, 0.44, 0.46), Vector3(sx, 0.22, z), steel, false)
		_box(Vector3(0.05, 0.05, 0.52), Vector3(sx, 0.465, z), steel, false)
		_box(Vector3(0.05, 0.5, 0.05), Vector3(sx, 0.72, z - 0.235), steel, false)
	# oturak citalari (hafif ton farkiyla)
	for i in 5:
		var wm := StandardMaterial3D.new()
		wm.albedo_color = Color(0.40, 0.29, 0.19) * (0.92 + 0.16 * (float(i * 37 % 10) / 10.0))
		wm.roughness = 0.62
		_box(Vector3(1.8, 0.032, 0.082), Vector3(x, 0.505, z - 0.2 + i * 0.1), wm, false)
	# sirtlik citalari
	for i in 2:
		var wm2 := StandardMaterial3D.new()
		wm2.albedo_color = Color(0.40, 0.29, 0.19) * (0.9 + 0.12 * float(i))
		wm2.roughness = 0.62
		_box(Vector3(1.8, 0.085, 0.032), Vector3(x, 0.66 + i * 0.13, z - 0.245), wm2, false)
	var sb := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(1.85, 1.0, 0.55)
	cs.shape = bs
	cs.position = Vector3(x, 0.5, z)
	sb.add_child(cs)
	add_child(sb)


## Metro cop kutusu: govde + agiz halkasi + siyah acikli k
func _bin(x: float) -> void:
	var z := 0.5
	var body := StandardMaterial3D.new()
	body.albedo_color = Color(0.13, 0.22, 0.18)
	body.metallic = 0.5
	body.roughness = 0.45
	_detail(body, 3.0, 0.4)
	var rim := StandardMaterial3D.new()
	rim.albedo_color = Color(0.1, 0.11, 0.11)
	rim.metallic = 0.7
	rim.roughness = 0.4
	_detail(rim, 3.0, 0.3)
	_tube(Vector3(x, 0.05, z), Vector3(x, 0.66, z), 0.215, body)
	_tube(Vector3(x, 0.64, z), Vector3(x, 0.71, z), 0.228, rim)
	_tube(Vector3(x, 0.705, z), Vector3(x, 0.72, z), 0.165, mat_void)
	_tube(Vector3(x, 0.0, z), Vector3(x, 0.06, z), 0.16, rim)
	var sb := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 0.24
	cyl.height = 0.72
	cs.shape = cyl
	cs.position = Vector3(x, 0.36, z)
	sb.add_child(cs)
	add_child(sb)


func _build_props() -> void:
	# --- istasyon tabelasi: karsi duvarda "HISAR-7" (metro oranlarinda ince bant) ---
	for sxp in [0.0, -9.5, 9.5]:
		_box(Vector3(3.2, 0.44, 0.05), Vector3(sxp, 2.05, PIT_Z1 - 0.03), mat_navy, false)
		var lbl := Label3D.new()
		lbl.text = "HİSAR-7"
		lbl.font_size = 128
		lbl.pixel_size = 0.002
		lbl.modulate = Color(0.92, 0.95, 0.97)
		lbl.outline_size = 16
		lbl.outline_modulate = Color(0.02, 0.04, 0.08)
		lbl.position = Vector3(sxp, 2.05, PIT_Z1 - 0.07)
		lbl.rotation.y = PI
		add_child(lbl)

	# --- CIKIS tabelasi: merdiven agzinin ustunde asili (ince, metro oranli) ---
	var back := _box(Vector3(0.95, 0.26, 0.05), Vector3(0, 2.78, 0.7), mat_navy, false)
	back.material_override = null
	var sgn := StandardMaterial3D.new()
	sgn.albedo_color = Color(0.015, 0.14, 0.06)
	sgn.emission_enabled = true
	sgn.emission = Color(0.08, 0.55, 0.24)
	sgn.emission_energy_multiplier = 0.9
	back.material_override = sgn
	var cl := Label3D.new()
	cl.text = "ÇIKIŞ"
	cl.font_size = 88
	cl.pixel_size = 0.0018
	cl.modulate = Color(0.9, 1.0, 0.93)
	cl.position = Vector3(0, 2.78, 0.73)
	add_child(cl)
	_tube(Vector3(-0.38, 2.91, 0.7), Vector3(-0.38, CEIL_Y, 0.7), 0.008, mat_metal)
	_tube(Vector3(0.38, 2.91, 0.7), Vector3(0.38, CEIL_Y, 0.7), 0.008, mat_metal)
	var sl := OmniLight3D.new()
	sl.light_color = Color(0.3, 0.95, 0.5)
	sl.light_energy = 0.25
	sl.omni_range = 1.8
	sl.position = Vector3(0, 2.55, 0.9)
	add_child(sl)

	# --- banklar: gercek fotogrametrik model (Poly Haven CC0), dogal olcek (4.34 m) ---
	_prop("res://assets/models/modular_street_seating/modular_street_seating.gltf",
			Vector3(-9.0, 0.0, 0.55), 0.0, 4.34)
	_prop("res://assets/models/modular_street_seating/modular_street_seating.gltf",
			Vector3(9.8, 0.0, 0.55), 0.0, 4.34)
	for bx2 in [-9.0, 9.8]:
		var bsb := StaticBody3D.new()
		var bcs := CollisionShape3D.new()
		var bbs := BoxShape3D.new()
		bbs.size = Vector3(4.4, 1.0, 0.75)
		bcs.shape = bbs
		bcs.position = Vector3(bx2, 0.5, 0.55)
		bsb.add_child(bcs)
		add_child(bsb)
	# bank yaninda cop kutusu
	_bin(-6.8)

	# --- Poly Haven CC0 modeller (fotorealistik taramalar) ---
	# islak zemin tabelasi: merdiven agzinin yakininda (SON SEFER ruhu)
	_prop("res://assets/models/WetFloorSign_01/WetFloorSign_01.gltf",
			Vector3(1.9, 0.0, 2.3), 25.0, 0.65)
	# bakim kosesi: peron ucunda varil + koliler
	_prop("res://assets/models/Barrel_01/Barrel_01.gltf",
			Vector3(-14.1, 0.0, 1.0), 10.0, 0.95)
	_prop("res://assets/models/cardboard_box_01/cardboard_box_01.gltf",
			Vector3(-13.3, 0.0, 0.65), 18.0, 0.55)
	_prop("res://assets/models/cardboard_box_01/cardboard_box_01.gltf",
			Vector3(-13.55, 0.0, 1.5), 55.0, 0.48)
	# yerde paslanmis teneke (bankin dibinde)
	_prop("res://assets/models/can_rusted/can_rusted.gltf",
			Vector3(-6.35, 0.0, 1.05), 70.0, 0.13)
	# kafesli endustriyel lambalar: tunel agizlarinda (donuk, sicak aksan)
	for sx in [-1.0, 1.0]:
		_prop("res://assets/models/caged_hanging_light/caged_hanging_light.gltf",
				Vector3(sx * (PLAT_L - 1.6), 2.62, 9.4), 0.0, 0.45, false)
		var cw := OmniLight3D.new()
		cw.light_color = Color(1.0, 0.8, 0.55)
		cw.light_energy = 0.4
		cw.omni_range = 4.5
		cw.shadow_enabled = true
		cw.shadow_blur = 2.0
		cw.position = Vector3(sx * (PLAT_L - 1.6), 2.45, 9.4)
		add_child(cw)

	# --- sigorta panolari: gercek model kiti (electrical_boxes.glb) ---
	# ana pano (CLAUDE.md ilk gorev nesnesi) + yaninda kucuk buat + orta kutu:
	# merdivene yakin servis kumesi. Duvara sirti yaslanir, on yuz perona bakar.
	_prop_named("res://assets/models/electrical_boxes/electrical_boxes.glb",
			"modular-box-01", Vector3(-4.5, 1.45, 0.0), -90.0)
	_prop_named("res://assets/models/electrical_boxes/electrical_boxes.glb",
			"modular-box-06", Vector3(-3.72, 1.85, 0.0), -90.0)
	_prop_named("res://assets/models/electrical_boxes/electrical_boxes.glb",
			"modular-box-02", Vector3(-5.15, 1.32, 0.0), -90.0)
	var led := StandardMaterial3D.new()
	led.albedo_color = Color(0.05, 0.2, 0.08)
	led.emission_enabled = true
	led.emission = Color(0.2, 1.0, 0.35)
	led.emission_energy_multiplier = 2.2
	_box(Vector3(0.022, 0.022, 0.018), Vector3(-4.28, 1.72, 0.115), led, false)
	var plbl := Label3D.new()
	plbl.text = "PANO A"
	plbl.font_size = 30
	plbl.pixel_size = 0.0014
	plbl.modulate = Color(0.72, 0.75, 0.77)
	plbl.position = Vector3(-4.5, 1.92, 0.03)
	add_child(plbl)

	# --- bozuk saat: merdiven agzinin sag ustunde, kucuk ---
	var clock_face := _tube(Vector3(4.1, 2.5, 0.0), Vector3(4.1, 2.5, 0.06), 0.165, mat_void)
	clock_face.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var face := _tube(Vector3(4.1, 2.5, 0.015), Vector3(4.1, 2.5, 0.068), 0.145, mat_paint)
	face.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# duran akrep/yelkovan (04:17)
	var hand1 := _box(Vector3(0.013, 0.095, 0.01), Vector3(4.124, 2.548, 0.074), mat_void, false)
	hand1.rotation.z = -0.5
	var hand2 := _box(Vector3(0.011, 0.125, 0.01), Vector3(4.07, 2.47, 0.074), mat_void, false)
	hand2.rotation.z = 1.9

	# --- posterler: duzenli araliklarla ---
	var pcolors := [Color(0.32, 0.38, 0.4), Color(0.42, 0.31, 0.24), Color(0.45, 0.45, 0.4),
			Color(0.25, 0.3, 0.36)]
	var pxs := [-11.6, -5.7, 5.6, 12.1]
	for i in 4:
		var frame := StandardMaterial3D.new()
		frame.albedo_color = Color(0.55, 0.57, 0.58)
		frame.metallic = 0.6
		frame.roughness = 0.4
		_detail(frame, 3.0, 0.25)
		_box(Vector3(0.66, 0.94, 0.022), Vector3(pxs[i], 1.62, 0.011), frame, false)
		var pm := StandardMaterial3D.new()
		pm.albedo_color = pcolors[i]
		pm.roughness = 0.6
		_detail(pm, 2.0, 0.35, true)
		_box(Vector3(0.6, 0.88, 0.02), Vector3(pxs[i], 1.62, 0.018), pm, false)

	# --- peron kenari uyari yazisi (karsi duvarda kucuk) ---
	var wlbl := Label3D.new()
	wlbl.text = "SARI ÇİZGİYİ GEÇMEYİNİZ"
	wlbl.font_size = 40
	wlbl.pixel_size = 0.0016
	wlbl.modulate = Color(0.75, 0.78, 0.8, 0.85)
	wlbl.position = Vector3(0, 0.35, PIT_Z1 - 0.09)
	wlbl.rotation.y = PI
	add_child(wlbl)


var _wood_mat: StandardMaterial3D = null
func _wood() -> StandardMaterial3D:
	if _wood_mat == null:
		_wood_mat = StandardMaterial3D.new()
		_wood_mat.albedo_color = Color(0.32, 0.24, 0.17)
		_wood_mat.roughness = 0.7
	return _wood_mat


# ------------------------------------------------------------------ korkuluklar

func _rail_run(pts: Array[Vector3], radius: float) -> void:
	for i in pts.size() - 1:
		_tube(pts[i], pts[i + 1], radius, mat_metal)
	for p in pts:
		_ball(p, radius * 1.03, mat_metal)


func _build_rails() -> void:
	var rx := HW - 0.085
	for hv in [0.92, 0.72]:
		var h: float = hv
		for side in [-1.0, 1.0]:
			# kose kolonundan uzak baslar; iki ucta duvara kivrilip ankraja girer
			var wp: Array[Vector3] = []
			for z in [-0.38, LAND_Z0, LAND_Z1, F2_END_Z, F2_END_Z - 0.4]:
				wp.append(Vector3(side * rx, _nose_y(z) + h, z))
			_rail_run(wp, 0.02)
			# uc dirsekleri: duvarin icine donus
			_tube(Vector3(side * (HW + 0.04), wp[0].y, wp[0].z), wp[0], 0.02, mat_metal)
			_tube(wp[wp.size() - 1],
					Vector3(side * (HW + 0.04), wp[wp.size() - 1].y, wp[wp.size() - 1].z),
					0.02, mat_metal)
			for i in range(0, wp.size() - 1):
				var m := (wp[i] + wp[i + 1]) * 0.5
				_tube(Vector3(side * HW, m.y - 0.045, m.z),
						Vector3(side * rx, m.y - 0.045, m.z), 0.011, mat_metal)
				_tube(Vector3(side * rx, m.y - 0.05, m.z),
						Vector3(side * rx, m.y, m.z), 0.011, mat_metal)
		# orta korkuluk — agizda kisa asagi kivrimla biter
		var cp: Array[Vector3] = [
			Vector3(0.0, h - 0.24, 0.18),
			Vector3(0.0, h, -0.05),
		]
		for z in [LAND_Z0, LAND_Z1, F2_END_Z + 0.3]:
			cp.append(Vector3(0.0, _nose_y(z) + h, z))
		_rail_run(cp, 0.021)
	for z in [-0.05, -1.1, -2.6, -4.2, -5.6, -7.2]:
		var base := Vector3(0, _nose_y(z), z)
		_tube(base, base + Vector3(0, 0.92, 0), 0.024, mat_metal)
	var sb := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(0.08, 3.4, -F2_END_Z + 1.0)
	cs.shape = bs
	cs.position = Vector3(0, 1.7, (F2_END_Z - 0.5) * 0.5)
	sb.add_child(cs)
	add_child(sb)
	# peron kenarindan dusme onleyici YOK — gercek peron; ama cukur carpismasi var
	# (cukura dusen oyuncu icin taban zaten collider)


# ------------------------------------------------------------------ isiklar

## Dugum agacinin birlesik AABB'si. Donus: [AABB, bulundu_mu]
func _calc_aabb(node: Node, xf: Transform3D) -> Array:
	var has := false
	var aabb := AABB()
	var local_xf := xf
	if node is Node3D:
		local_xf = xf * (node as Node3D).transform
	if node is MeshInstance3D:
		aabb = local_xf * (node as MeshInstance3D).get_aabb()
		has = true
	for c in node.get_children():
		var r := _calc_aabb(c, local_xf)
		if r[1]:
			aabb = aabb.merge(r[0]) if has else r[0]
			has = true
	return [aabb, has]


## Floresan: GLB armatur + parlayan tup + titrek isik.
func _fixture(pos: Vector3, energy: float, color: Color, flicker: float,
		dropout: float, light_offset := Vector3(0, -0.3, 0),
		rot := Vector3.ZERO, use_model := true) -> void:
	var holder := Node3D.new()
	holder.position = pos
	holder.rotation = rot
	add_child(holder)

	if use_model and _lamp_scene:
		var fx: Node3D = _lamp_scene.instantiate()
		var res := _calc_aabb(fx, Transform3D.IDENTITY)
		if res[1]:
			var aabb: AABB = res[0]
			var s := aabb.size
			var rotb := Basis.IDENTITY
			if s.y >= s.x and s.y >= s.z:
				rotb = Basis(Vector3(0, 0, 1), PI * 0.5)
			elif s.z >= s.x and s.z >= s.y:
				rotb = Basis(Vector3(0, 1, 0), PI * 0.5)
			var longest: float = maxf(s.x, maxf(s.y, s.z))
			var scale := 1.3 / maxf(longest, 0.001)
			fx.transform = Transform3D(rotb.scaled(Vector3.ONE * scale),
					-(rotb * (aabb.get_center())) * scale)
			holder.add_child(fx)
		else:
			fx.queue_free()

	var tube := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.016
	cap.height = 1.15
	tube.mesh = cap
	var tm := StandardMaterial3D.new()
	tm.albedo_color = Color(0.85, 0.92, 1.0)
	tm.emission_enabled = true
	tm.emission = color
	tm.emission_energy_multiplier = 5.0 * clampf(energy / 3.0, 0.12, 2.0)
	tube.material_override = tm
	tube.rotation.z = PI * 0.5
	tube.position = Vector3(0, -0.055, 0)
	holder.add_child(tube)

	var light := OmniLight3D.new()
	light.set_script(load("res://scripts/flicker_light.gd"))
	light.position = light_offset
	light.light_color = color
	light.omni_range = 8.0
	light.shadow_enabled = true
	light.shadow_blur = 3.0
	light.light_energy = energy
	light.set("base_energy", energy)
	light.set("flicker_amount", flicker)
	light.set("dropout_threshold", dropout)
	light.set("tube", tube)
	holder.add_child(light)

	# cizirti: yanan tuplerin konumsal viziltisi (titredikce bozulur)
	if energy > 0.25:
		if _buzz_stream == null:
			_buzz_stream = _make_buzz()
		var bz := AudioStreamPlayer3D.new()
		bz.stream = _buzz_stream
		bz.volume_db = -34.0 + clampf(energy, 0.0, 3.0) * 2.0
		bz.pitch_scale = 0.96 + randf() * 0.08
		bz.unit_size = 1.6
		bz.max_distance = 9.0
		bz.autoplay = true
		holder.add_child(bz)
		light.set("buzz", bz)


func _build_lights() -> void:
	# merdiven: duzluk uzerinde ana tup (soguk, baskin)
	_fixture(Vector3(0, 4.28, -3.2), 2.8, Color(0.76, 0.90, 1.0),
			0.10, 0.82, Vector3(0, -0.35, 0))
	# ust kol armaturu — bozuk, cogunlukla sonuk, karanligin esiginde
	_fixture(Vector3(0, 5.68, -6.6), 0.5, Color(0.8, 0.9, 1.0),
			0.5, 0.3, Vector3(0, -0.3, 0))
	# peron isik sirasi: kimi saglam, biri titrek, biri olu (CLAUDE.md atmosferi)
	var xs := [-13.0, -8.66, -4.33, 0.0, 4.33, 8.66, 13.0]
	var energies := [0.9, 1.4, 1.5, 1.6, 0.1, 1.5, 0.9]
	var flickers := [0.12, 0.55, 0.08, 0.06, 0.6, 0.08, 0.15]
	var drops := [0.8, 0.3, 0.9, 0.92, 0.15, 0.9, 0.75]
	for i in xs.size():
		_fixture(Vector3(xs[i], CEIL_Y - 0.08, 3.6), energies[i],
				Color(0.78, 0.9, 1.0), flickers[i], drops[i], Vector3(0, -0.35, 0))
	# tunel agizlarina sizan cok soluk isik (derinlik hissi)
	for sx in [-1.0, 1.0]:
		var t := OmniLight3D.new()
		t.light_color = Color(0.55, 0.7, 0.85)
		t.light_energy = 0.35
		t.omni_range = 7.0
		t.position = Vector3(sx * (PLAT_L - 2.5), 1.2, (PIT_Z0 + PIT_Z1) * 0.5)
		add_child(t)
	# ray cukuru uzeri donuk aydinlatma (raylar hafif parlasin, cukur okunsun)
	for px in [-6.0, 0.0, 6.0]:
		var d := OmniLight3D.new()
		d.light_color = Color(0.6, 0.72, 0.85)
		d.light_energy = 0.3
		d.omni_range = 6.5
		d.shadow_enabled = true
		d.shadow_blur = 2.5
		d.position = Vector3(px, 2.6, (PIT_Z0 + PIT_Z1) * 0.5)
		add_child(d)


# ------------------------------------------------------------------ ortam + ses

func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0, 0, 0)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_DISABLED

	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	env.tonemap_exposure = 0.85

	env.sdfgi_enabled = true
	env.sdfgi_use_occlusion = true
	env.sdfgi_bounce_feedback = 0.3
	env.sdfgi_min_cell_size = 0.15
	env.sdfgi_energy = 0.8

	env.ssao_enabled = true
	env.ssao_intensity = 1.6
	env.ssao_radius = 1.2
	env.ssil_enabled = true
	env.ssil_intensity = 0.8

	env.ssr_enabled = true
	env.ssr_max_steps = 56
	env.ssr_fade_in = 0.15
	env.ssr_fade_out = 2.0

	env.glow_enabled = true
	env.glow_intensity = 0.55
	env.glow_bloom = 0.04
	env.glow_hdr_threshold = 1.1
	env.set("glow_levels/2", 0.6)
	env.set("glow_levels/4", 0.8)

	env.volumetric_fog_enabled = true
	env.volumetric_fog_density = 0.01
	env.volumetric_fog_albedo = Color(0.7, 0.8, 0.85)
	env.volumetric_fog_length = 40.0
	env.volumetric_fog_anisotropy = 0.4

	env.adjustment_enabled = true
	env.adjustment_brightness = 0.96
	env.adjustment_contrast = 1.05
	env.adjustment_saturation = 0.85

	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	var probe := ReflectionProbe.new()
	probe.size = Vector3(32.0, 9.0, 14.0)
	probe.position = Vector3(0, 2.4, 5.6)
	probe.box_projection = true
	probe.interior = true
	probe.update_mode = ReflectionProbe.UPDATE_ONCE
	probe.intensity = 0.7
	add_child(probe)


func _build_audio() -> void:
	# Ana gerilim: "Unseen Horrors" — Kevin MacLeod (incompetech.com, CC-BY 4.0).
	# Gercek korku ambiyansi: yavas gelisen, rahatsiz edici.
	var stream: AudioStream = load("res://assets/audio/tension.mp3")
	if stream != null:
		if stream is AudioStreamMP3:
			(stream as AudioStreamMP3).loop = true
		var mus := AudioStreamPlayer.new()
		mus.stream = stream
		mus.volume_db = -12.0
		mus.autoplay = true
		add_child(mus)
		mus.play()

	# tunel agizlari: sabit derin ugultu (konumsal — yaklastikca buyur)
	var rumble: AudioStream = load("res://assets/audio/dark_drone.ogg")
	if rumble != null and rumble is AudioStreamOggVorbis:
		(rumble as AudioStreamOggVorbis).loop = true
		for sx in [-1.0, 1.0]:
			var r := AudioStreamPlayer3D.new()
			r.stream = rumble
			r.volume_db = -6.0
			r.pitch_scale = 0.55 if sx < 0.0 else 0.62
			r.unit_size = 3.5
			r.max_distance = 26.0
			r.autoplay = true
			r.position = Vector3(sx * (PLAT_L + 1.5), 1.0, (PIT_Z0 + PIT_Z1) * 0.5)
			add_child(r)

	# bolge tetikli korku sesleri (Vinrax "Horror Ambient" — tek seferlik sting)
	var sting: AudioStream = load("res://assets/audio/horror_main.ogg")
	if sting != null:
		# ust merdivenin karanligi: iceri adim atinca
		_trigger_sound(Vector3(0, TOP_Y + 1.5, F2_END_Z + 0.8), Vector3(W, 3.0, 1.6),
				sting, -8.0, 0.9, 90.0)
		# tunel agizlarina fazla yaklasinca (iki uc, farkli pitch)
		_trigger_sound(Vector3(-PLAT_L + 1.8, 1.5, PLAT_D - 1.0), Vector3(3.0, 3.0, 2.2),
				sting, -10.0, 0.72, 120.0)
		_trigger_sound(Vector3(PLAT_L - 1.8, 1.5, PLAT_D - 1.0), Vector3(3.0, 3.0, 2.2),
				sting, -10.0, 0.66, 120.0)
		# duzluk — nadir, cok kisik fisilti hissi
		_trigger_sound(Vector3(0, F1_RISE + 1.5, LAND_Z0 - 1.0), Vector3(W, 2.5, 1.8),
				sting, -16.0, 1.15, 150.0)


# ------------------------------------------------------------------ post fx + oyuncu

func _build_post_fx() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)

	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var pm := ShaderMaterial.new()
	pm.shader = load("res://shaders/post_grade.gdshader")
	rect.material = pm
	rect.add_to_group("post_fx")
	layer.add_child(rect)

	var lbl := Label.new()
	lbl.add_to_group("zoom_label")
	lbl.text = ""
	lbl.visible = false
	lbl.position = Vector2(24, 24)
	lbl.add_theme_color_override("font_color", Color(0.85, 0.95, 1.0, 0.75))
	lbl.add_theme_font_size_override("font_size", 22)
	layer.add_child(lbl)


func _spawn_player() -> void:
	var p := CharacterBody3D.new()
	p.set_script(load("res://scripts/player.gd"))
	p.position = Vector3(2.5, 0.02, 5.2)
	p.add_to_group("player")
	add_child(p)
	# siluet korkutmacasi: peron ucunda arkani donunce merdivene kacan figur
	var scare := Node3D.new()
	scare.set_script(load("res://scripts/scare_figure.gd"))
	scare.set("sting", load("res://assets/audio/horror_main.ogg"))
	add_child(scare)


# ------------------------------------------------------------------ otomatik ekran goruntusu

func _maybe_screenshot() -> void:
	var args := OS.get_cmdline_user_args()
	var shot_path := ""
	var yaw := 25.0
	var pitch := 4.0
	for a in args:
		if a.begins_with("--shot="):
			shot_path = a.trim_prefix("--shot=")
		elif a.begins_with("--yaw="):
			yaw = float(a.trim_prefix("--yaw="))
		elif a.begins_with("--pitch="):
			pitch = float(a.trim_prefix("--pitch="))
	if shot_path.is_empty():
		return
	var p: Node = null
	for c in get_children():
		if c is CharacterBody3D:
			p = c
			break
	if p:
		p.call("set_view", yaw, pitch)
		p.set_process_unhandled_input(false)
	_do_screenshot(shot_path)


func _do_screenshot(path: String) -> void:
	for i in 150:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(path)
	print("SHOT_SAVED:", path)
	get_tree().quit()
