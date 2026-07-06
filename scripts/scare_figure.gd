extends Node3D
## Siluet korkutmacasi: oyuncu peronun ucuna gidip arkasini donunce,
## karanlik bir figur hizla merdivene kosup karanlikta kaybolur.
## Bir kez tetiklenir (uzun sogutmali). Asla oyuncuya yaklasmaz — sadece gorulur.

@export var arm_zone_x := 9.0           # bu |x|'in otesi "koridor ucu"
@export var run_from := Vector3(2.4, 0.0, 2.8)   # CAUTION tabelasinin yani
@export var run_to := Vector3(0.3, 0.0, -0.8)    # merdiven agzinin ici
@export var run_dur := 1.9
@export var cooldown := 10.0            # TEST degeri — yayinda 300 yapilacak
@export var sting: AudioStream

var _state := 0                          # 0 bekle, 1 kurulu, 2 kosuyor, 3 bitti
var _t := 0.0
var _last_fire := -1e9
var _figure: Node3D
var _fig_mats: Array[ShaderMaterial] = []
var _audio: AudioStreamPlayer3D


func _ready() -> void:
	_figure = Node3D.new()
	add_child(_figure)
	var wraith := load("res://shaders/wraith.gdshader")
	# ic ice iki duman kabugu: koyu cekirdek + genis hayalet ortusu
	var shells := [
		{"r": 0.22, "h": 1.85, "sx": 0.72, "y": 1.12, "phase": 0.0},
		{"r": 0.34, "h": 2.15, "sx": 0.68, "y": 1.15, "phase": 2.7},
	]
	for s in shells:
		var mi := MeshInstance3D.new()
		var cap := CapsuleMesh.new()
		cap.radius = s.r
		cap.height = s.h
		cap.radial_segments = 32
		cap.rings = 16
		mi.mesh = cap
		var m := ShaderMaterial.new()
		m.shader = wraith
		m.set_shader_parameter("phase", s.phase)
		_fig_mats.append(m)
		mi.material_override = m
		mi.position.y = s.y
		mi.scale = Vector3(s.sx, 1.0, 1.0)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_figure.add_child(mi)
	_figure.visible = false

	_audio = AudioStreamPlayer3D.new()
	_audio.stream = sting
	_audio.volume_db = -13.0
	_audio.pitch_scale = 1.2
	_audio.max_distance = 24.0
	_figure.add_child(_audio)


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

	# TEST: T tusu kosulsuz tetikler (yayinda kaldirilacak)
	if _state != 2 and Input.is_physical_key_pressed(KEY_T):
		_fire(now)
		return

	match _state:
		0:
			# oyuncu peron ucunda ve merdivene SIRTI donukse kur (gevsek esik)
			if now - _last_fire > cooldown and absf(p.position.x) > arm_zone_x:
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
			# suzulerek kayip gitme: ayak yok, temas yok — sadece akis
			var ke := k * k * (3.0 - 2.0 * k)
			var pos := run_from.lerp(run_to, ke)
			pos.y = 0.10 + sin(_t * 2.3) * 0.05  # yerden hafif yukseklikte salinim
			_figure.position = pos
			var dir := (run_to - run_from).normalized()
			_figure.look_at(_figure.global_position + dir, Vector3.UP)
			_figure.rotate_object_local(Vector3(1, 0, 0), 0.14)  # one meyilli suzulus
			_figure.scale = Vector3(1.0, 1.0, 1.22)  # hareket yonunde iz/uzama
			# hizla belirir (%15), sonda erir (%35)
			var alpha := 1.0
			if k < 0.15:
				alpha = k / 0.15
			elif k > 0.65:
				alpha = 1.0 - (k - 0.65) / 0.35
			for mm in _fig_mats:
				mm.set_shader_parameter("alpha_mul", alpha)
			if k >= 1.0:
				_figure.visible = false
				_state = 3
		3:
			# sogutma dolunca yeniden silahlanabilir
			if now - _last_fire > cooldown:
				_state = 0
