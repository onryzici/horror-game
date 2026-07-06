extends Node3D
## Siluet korkutmacasi: oyuncu peronun ucuna gidip arkasini donunce,
## karanlik bir figur hizla merdivene kosup karanlikta kaybolur.
## Bir kez tetiklenir (uzun sogutmali). Asla oyuncuya yaklasmaz — sadece gorulur.

@export var arm_zone_x := 9.0           # bu |x|'in otesi "koridor ucu"
@export var run_from := Vector3(2.4, 0.0, 2.8)   # CAUTION tabelasinin yani
@export var run_to := Vector3(0.3, 0.0, -0.8)    # merdiven agzinin ici
@export var run_dur := 2.4              # rota uzadi (merdiven cikisi) — hiz ayni kalsin
@export var linger_dur := 0.9           # merdiven agzinda durup baktigi sure
@export var fade_dur := 1.5             # sonrasinda yavasca erime
@export var cooldown := 300.0           # tekrar tekrar tetiklenmesin — nadir kalsin
@export var enabled := false            # gorev zinciri acana kadar devrede degil
@export var sting: AudioStream

const PUFF_LIFE := 0.9                   # duman izi parcaciginin omru

var _state := 0                          # 0 bekle, 1 kurulu, 2 kosuyor, 3 bitti, 4 eriyor
var _t := 0.0
var _last_fire := -1e9
var _figure: Node3D
var _fig_mats: Array[ShaderMaterial] = []
var _fig_alpha: Array[float] = []        # parca basina taban opaklik
var _audio: AudioStreamPlayer3D
var _wraith: Shader
var _puffs: Array = []                   # [mesh, mat, age] — arkada kalan duman
var _puff_timer := 0.0
var _path: Array[Vector3] = []           # merdivenden yukari cikan rota
var _seg_len: Array[float] = []
var _total_len := 0.0
var _linger_y := 0.0                     # duraksama evresindeki taban yukseklik


## Insansi silüet: kafa + govde + kollar + bacaklar, ustune duman ortusu.
## Hepsi wraith shader'iyla — sekil insan, doku hala sis/karalti. Boy ~2.1 m.
func _ready() -> void:
	_figure = Node3D.new()
	add_child(_figure)
	_wraith = load("res://shaders/wraith.gdshader")
	var parts := [
		# [radius, height, pos, scale_x, phase, taban_opaklik, kesiflik]
		[0.13, 0.30, Vector3(0.0, 2.02, 0.0), 0.92, 0.0, 1.0, 0.6],    # kafa
		[0.19, 0.95, Vector3(0.0, 1.42, 0.0), 0.80, 1.3, 1.0, 0.6],    # govde
		[0.065, 0.80, Vector3(-0.27, 1.28, 0.0), 1.0, 2.1, 1.0, 0.5],  # sol kol
		[0.065, 0.80, Vector3(0.27, 1.28, 0.0), 1.0, 3.4, 1.0, 0.5],   # sag kol
		[0.085, 1.00, Vector3(-0.12, 0.52, 0.0), 1.0, 4.2, 1.0, 0.5],  # sol bacak
		[0.085, 1.00, Vector3(0.12, 0.52, 0.0), 1.0, 5.0, 1.0, 0.5],   # sag bacak
		[0.36, 2.30, Vector3(0.0, 1.22, 0.0), 0.70, 2.7, 0.32, 0.0],   # duman ortusu (seffaf)
	]
	for s in parts:
		var mi := MeshInstance3D.new()
		var cap := CapsuleMesh.new()
		cap.radius = s[0]
		cap.height = s[1]
		cap.radial_segments = 24
		cap.rings = 12
		mi.mesh = cap
		var m := ShaderMaterial.new()
		m.shader = _wraith
		m.set_shader_parameter("phase", s[4])
		m.set_shader_parameter("solidity", s[6])
		_fig_mats.append(m)
		_fig_alpha.append(s[5])
		mi.material_override = m
		mi.position = s[2]
		mi.scale = Vector3(s[3], 1.0, 1.0)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_figure.add_child(mi)
	_figure.visible = false
	# rota: peron → merdiven dibi → 1. kol boyunca yukari → sahanlik karanligi
	_path = [
		run_from,
		Vector3(0.35, 0.0, -0.5),
		Vector3(0.0, 1.24, -2.75),
		Vector3(0.0, 1.28, -4.1),
	]
	_seg_len.clear()
	_total_len = 0.0
	for i in _path.size() - 1:
		var l := _path[i].distance_to(_path[i + 1])
		_seg_len.append(l)
		_total_len += l

	_audio = AudioStreamPlayer3D.new()
	_audio.stream = sting
	_audio.volume_db = -7.0
	_audio.pitch_scale = 1.0   # nefes dogal tonunda kalsin
	_audio.max_distance = 26.0
	_figure.add_child(_audio)


## Yay uzunluguna gore rota uzerinde konum (u: 0..1)
func _path_pos(u: float) -> Vector3:
	var d := clampf(u, 0.0, 1.0) * _total_len
	for i in _seg_len.size():
		if d <= _seg_len[i] or i == _seg_len.size() - 1:
			return _path[i].lerp(_path[i + 1], d / maxf(_seg_len[i], 0.001))
		d -= _seg_len[i]
	return _path[-1]


## Arkada birakilan duman izi: figurun gecmis konumunda beliren,
## buyuyup yukari suzulerek sonen yari-saydam kapsul.
func _spawn_puff() -> void:
	var mi := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = randf_range(0.22, 0.3)
	cap.height = randf_range(1.5, 2.0)
	cap.radial_segments = 16
	cap.rings = 8
	mi.mesh = cap
	var m := ShaderMaterial.new()
	m.shader = _wraith
	m.set_shader_parameter("phase", randf() * 6.28)
	m.set_shader_parameter("alpha_mul", 0.26)
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = _figure.position + Vector3(randf_range(-0.06, 0.06), 1.12,
			randf_range(-0.06, 0.06))
	add_child(mi)
	_puffs.append([mi, m, 0.0])


func _update_puffs(delta: float) -> void:
	var i := _puffs.size() - 1
	while i >= 0:
		var p: Array = _puffs[i]
		p[2] += delta
		var k: float = p[2] / PUFF_LIFE
		if k >= 1.0:
			(p[0] as Node).queue_free()
			_puffs.remove_at(i)
		else:
			var mi := p[0] as MeshInstance3D
			mi.position.y += delta * 0.25            # yukari suzulme
			var g := 1.0 + k * 0.7                    # dagilarak buyume
			mi.scale = Vector3(g, g, g)
			(p[1] as ShaderMaterial).set_shader_parameter("alpha_mul",
					0.26 * (1.0 - k) * (1.0 - k))
		i -= 1


func _fire(now: float) -> void:
	_state = 2
	_t = 0.0
	_last_fire = now
	for mm in _fig_mats:
		mm.set_shader_parameter("alpha_mul", 0.0)  # belirerek girer
	_figure.visible = true
	_audio.play()


func _process(delta: float) -> void:
	var p := get_tree().get_first_node_in_group("player") as CharacterBody3D
	if p == null:
		return
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var now := Time.get_ticks_msec() / 1000.0
	_update_puffs(delta)

	match _state:
		0:
			# oyuncu PERON ucunda (ust katta degil) ve merdivene sirti donukse kur
			if enabled and now - _last_fire > cooldown \
					and absf(p.position.x) > arm_zone_x and p.position.y < 1.5:
				var to_stairs := (Vector3(0, 1.2, 0) - cam.global_position).normalized()
				if -cam.global_transform.basis.z.dot(to_stairs) < -0.05:
					_state = 1
		1:
			if absf(p.position.x) < arm_zone_x - 1.5:
				_state = 0  # zonu terk etti, kurulumu boz
				return
			# arkasini donup merdiven yonune bakinca: kos!
			var to_stairs2 := (Vector3(0, 1.2, 0) - cam.global_position).normalized()
			if -cam.global_transform.basis.z.dot(to_stairs2) > 0.4:
				_fire(now)
		2:
			_t += delta
			var k := clampf(_t / run_dur, 0.0, 1.0)
			# suzulerek merdivenden yukari: ayak yok, temas yok — sadece akis
			var ke := k * k * (3.0 - 2.0 * k)
			var pos := _path_pos(ke)
			pos.y += 0.10 + sin(_t * 2.3) * 0.05  # zeminden hafif yukseklikte salinim
			_figure.position = pos
			var dir := (_path_pos(minf(ke + 0.03, 1.0)) - _path_pos(ke))
			if dir.length() > 0.001:
				dir.y = 0.0
				_figure.look_at(_figure.global_position + dir.normalized(), Vector3.UP)
			_figure.rotate_object_local(Vector3(1, 0, 0), 0.14)  # one meyilli suzulus
			_figure.scale = Vector3(1.0, 1.0, 1.22)  # hareket yonunde iz/uzama
			# hizla belirir (%12); kosarken KAYBOLMAZ — sonda merdivende duraksar
			var alpha := minf(k / 0.12, 1.0)
			for i in _fig_mats.size():
				_fig_mats[i].set_shader_parameter("alpha_mul", alpha * _fig_alpha[i])
			# arkasinda duman izi birakir
			_puff_timer += delta
			if _puff_timer > 0.07 and k > 0.1:
				_puff_timer = 0.0
				_spawn_puff()
			if k >= 1.0:
				_state = 4
				_t = 0.0
				_linger_y = _figure.position.y
		4:
			# sahanlik karanliginda bir an durur (sanki bakar), sonra yavasca erir
			_t += delta
			_figure.position.y = _linger_y + sin(_t * 1.7) * 0.03
			_figure.scale = Vector3(1.0, 1.0, 1.0)  # durunca iz/uzama biter
			var fade := 1.0
			if _t > linger_dur:
				fade = 1.0 - clampf((_t - linger_dur) / fade_dur, 0.0, 1.0)
			for i in _fig_mats.size():
				_fig_mats[i].set_shader_parameter("alpha_mul", fade * _fig_alpha[i])
			if fade <= 0.0:
				_figure.visible = false
				_state = 3
		3:
			# sogutma dolunca yeniden silahlanabilir
			if now - _last_fire > cooldown:
				_state = 0
