extends Node
## Guvenlik kamerasi sistemi: ofisteki retro bilgisayardan acilir (E).
## 4 kanal; goruntu SubViewport'tan gercek sahne. Kanal degistirdikce
## arada anomaliler belirir (uzakta duran golge) + parazit.
## 1-4 kanal secer, E/ESC kapatir.

const CHANNELS := [
	{"name": "K-1  PERON BATI", "pos": Vector3(-14.0, 3.0, 6.8),
		"look": Vector3(2.0, 0.8, 3.4), "ghost": Vector3(-5.5, 0.0, 3.2)},
	{"name": "K-2  PERON DOĞU", "pos": Vector3(14.0, 3.0, 6.8),
		"look": Vector3(-2.0, 0.8, 3.4), "ghost": Vector3(6.5, 0.0, 3.0)},
	{"name": "K-3  ÜST HOL", "pos": Vector3(7.6, 6.0, -21.6),
		"look": Vector3(-1.0, 3.8, -13.5), "ghost": Vector3(0.5, 3.1, -18.2)},
	{"name": "K-4  MERDİVEN", "pos": Vector3(2.55, 5.5, -9.9),
		"look": Vector3(-0.4, 1.6, -2.6), "ghost": Vector3(0.2, 1.24, -3.6)},
]

var _open := false
var _channel := 0
var _vp: SubViewport
var _cam: Camera3D
var _layer: CanvasLayer
var _feed: TextureRect
var _ch_lbl: Label
var _time_lbl: Label
var _rec_lbl: Label
var _t := 0.0
var _ghost: Node3D
var _ghost_timer: SceneTreeTimer
var _rng := RandomNumberGenerator.new()
var _static_sp: AudioStreamPlayer


func _ready() -> void:
	add_to_group("cctv")
	_rng.seed = 31
	_vp = SubViewport.new()
	_vp.size = Vector2i(768, 576)
	_vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(_vp)
	_cam = Camera3D.new()
	_cam.fov = 68.0
	_cam.near = 0.05
	_vp.add_child(_cam)

	_layer = CanvasLayer.new()
	_layer.layer = 16
	_layer.visible = false
	add_child(_layer)
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.03, 0.02)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_layer.add_child(bg)
	_feed = TextureRect.new()
	_feed.texture = _vp.get_texture()
	_feed.set_anchors_preset(Control.PRESET_FULL_RECT)
	_feed.offset_left = 120.0
	_feed.offset_right = -120.0
	_feed.offset_top = 40.0
	_feed.offset_bottom = -40.0
	_feed.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_feed.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_feed.modulate = Color(0.72, 0.95, 0.8)     # eski monokrom kamera tonu
	_layer.add_child(_feed)

	var f: FontFile = load("res://assets/fonts/BarlowCondensed-SemiBold.ttf")
	_ch_lbl = _mk_label(f, 34, Color(0.85, 1.0, 0.9))
	_ch_lbl.position = Vector2(150, 58)
	_layer.add_child(_ch_lbl)
	_time_lbl = _mk_label(f, 30, Color(0.85, 1.0, 0.9))
	_time_lbl.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_time_lbl.position = Vector2(-330, 58)
	_time_lbl.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_layer.add_child(_time_lbl)
	_rec_lbl = _mk_label(f, 30, Color(1.0, 0.25, 0.2))
	_rec_lbl.text = "●  REC"
	_rec_lbl.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_rec_lbl.position = Vector2(-150, 58)
	_rec_lbl.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_layer.add_child(_rec_lbl)
	var hint := _mk_label(f, 24, Color(0.6, 0.75, 0.65))
	hint.text = "1-4  KAMERA DEĞİŞTİR        [E]  ÇIK"
	hint.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	hint.position = Vector2(150, -70)
	hint.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_layer.add_child(hint)

	# kanal gecis paraziti
	_static_sp = AudioStreamPlayer.new()
	_static_sp.stream = _make_static()
	_static_sp.volume_db = -14.0
	add_child(_static_sp)


func _mk_label(f: FontFile, size: int, col: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_override("font", f)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	return l


func _make_static() -> AudioStreamWAV:
	var rate := 16000
	var n := int(rate * 0.16)
	var data := PackedByteArray()
	data.resize(n * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	for i in n:
		var t := float(i) / float(rate)
		var env := 1.0 - t / 0.16
		data.encode_s16(i * 2, int(rng.randf_range(-1.0, 1.0) * env * 0.5 * 32767.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.data = data
	return w


func open() -> void:
	if _open:
		return
	_open = true
	var p := get_tree().get_first_node_in_group("player")
	if p:
		p.set("locked", true)
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_layer.visible = true
	_set_channel(0)


func close() -> void:
	if not _open:
		return
	_open = false
	_layer.visible = false
	_vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	_kill_ghost()
	var p := get_tree().get_first_node_in_group("player")
	if p:
		p.set("locked", false)


func _set_channel(i: int) -> void:
	_channel = i
	var ch: Dictionary = CHANNELS[i]
	_cam.position = ch["pos"]
	_cam.look_at_from_position(ch["pos"], ch["look"], Vector3.UP)
	_ch_lbl.text = str(ch["name"])
	_static_sp.play()
	_kill_ghost()
	# arada: kanalda kisa sure gorunen golge (anomali)
	if _rng.randf() < 0.4:
		_ghost_timer = get_tree().create_timer(_rng.randf_range(1.2, 4.0))
		var want := i
		_ghost_timer.timeout.connect(func() -> void:
			if _open and _channel == want:
				_spawn_ghost(ch["ghost"]))


## Kanalin gordugu bir noktada kisa sureligine duran siyah figur
func _spawn_ghost(at: Vector3) -> void:
	_ghost = Node3D.new()
	_ghost.position = at
	var wraith: Shader = load("res://shaders/wraith.gdshader")
	var parts := [
		[0.12, 0.28, Vector3(0.0, 1.62, 0.0)],
		[0.17, 0.85, Vector3(0.0, 1.05, 0.0)],
		[0.08, 0.9, Vector3(-0.11, 0.45, 0.0)],
		[0.08, 0.9, Vector3(0.11, 0.45, 0.0)],
	]
	for s in parts:
		var mi := MeshInstance3D.new()
		var cap := CapsuleMesh.new()
		cap.radius = s[0]
		cap.height = s[1]
		mi.mesh = cap
		var m := ShaderMaterial.new()
		m.shader = wraith
		m.set_shader_parameter("solidity", 0.92)
		m.set_shader_parameter("alpha_mul", 1.0)
		mi.material_override = m
		mi.position = s[2]
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_ghost.add_child(mi)
	get_tree().current_scene.add_child(_ghost)
	# parazit vurgusu
	_static_sp.play()
	get_tree().create_timer(_rng.randf_range(1.1, 2.2)).timeout.connect(_kill_ghost)


func _kill_ghost() -> void:
	if _ghost and is_instance_valid(_ghost):
		_ghost.queue_free()
	_ghost = null


func _unhandled_input(event: InputEvent) -> void:
	if not _open:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_E, KEY_ESCAPE:
				close()
				get_viewport().set_input_as_handled()
			KEY_1: _set_channel(0)
			KEY_2: _set_channel(1)
			KEY_3: _set_channel(2)
			KEY_4: _set_channel(3)


func _process(delta: float) -> void:
	if not _open:
		return
	_t += delta
	# saat: 03:47'den akar
	var secs := int(_t)
	var totm := 47 + secs / 60
	_time_lbl.text = "%02d:%02d:%02d" % [(3 + totm / 60) % 24, totm % 60, secs % 60]
	_rec_lbl.visible = fmod(_t, 1.0) < 0.62
	# hafif parazit titremesi
	var n := 0.93 + 0.07 * sin(_t * 61.0) * sin(_t * 17.3)
	_feed.modulate = Color(0.72 * n, 0.95 * n, 0.8 * n)
