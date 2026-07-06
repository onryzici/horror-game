extends CanvasLayer
## Telsis — MERKEZ'in sesi (CLAUDE.md §4.2'nin ilk adimi).
## Simdilik ses yok: her replik oncesi kisa parazit cizirtisi + ekran altinda altyazi.
## say() kuyruga ekler, replikler sirayla akar. VO eklenince ayni API kullanilir.

var _lbl: Label
var _panel: PanelContainer
var _queue: Array = []
var _busy := false
var _sp: AudioStreamPlayer
var _voice: AudioStreamPlayer


func _ready() -> void:
	layer = 9
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	# oyun tarzi altyazi kutusu: yari saydam siyah panel, ortalanmis, alta yakin
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_panel.offset_bottom = -58.0
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.0, 0.0, 0.0, 0.62)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 26.0
	sb.content_margin_right = 26.0
	sb.content_margin_top = 12.0
	sb.content_margin_bottom = 14.0
	_panel.add_theme_stylebox_override("panel", sb)
	_panel.visible = false
	root.add_child(_panel)

	_lbl = Label.new()
	_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lbl.custom_minimum_size = Vector2(980, 0)
	_lbl.add_theme_font_override("font", load("res://assets/fonts/Barlow-Medium.ttf"))
	_lbl.add_theme_font_size_override("font_size", 34)
	_lbl.add_theme_color_override("font_color", Color(0.93, 0.96, 0.94))
	_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	_lbl.add_theme_constant_override("outline_size", 4)
	_lbl.text = ""
	_panel.add_child(_lbl)

	_sp = AudioStreamPlayer.new()
	_sp.stream = _make_static()
	_sp.volume_db = -16.0
	add_child(_sp)

	# "yalandan" telsis sesi: anlasiilmaz bogyk konusma miriltisi (loop)
	_voice = AudioStreamPlayer.new()
	_voice.stream = _make_voice()
	_voice.volume_db = -13.0
	add_child(_voice)


## Kisa telsis parazidi (replik girisinde caliniyor)
func _make_static() -> AudioStreamWAV:
	var rate := 16000
	var n := int(rate * 0.26)
	var data := PackedByteArray()
	data.resize(n * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for i in n:
		var t := float(i) / float(rate)
		var env := (1.0 - t / 0.26) * (0.4 + 0.6 * absf(sin(TAU * 23.0 * t)))
		var v := rng.randf_range(-1.0, 1.0) * env * 0.55
		data.encode_s16(i * 2, int(clampf(v, -1.0, 1.0) * 32767.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.data = data
	return w


## Anlasilmaz "telsiz konusmasi": hece zarfli, pes tonlu, bant-sikistirilmis mirilti.
## Gercek VO gelene kadar konusma hissi verir; her replikte pitch degisir.
func _make_voice() -> AudioStreamWAV:
	var rate := 16000
	var dur := 6.0
	var n := int(rate * dur)
	var data := PackedByteArray()
	data.resize(n * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var phase := 0.0
	var amp := 0.0
	var target := 0.0
	var next_toggle := 0.0
	var lp := 0.0
	for i in n:
		var t := float(i) / float(rate)
		if t >= next_toggle:
			if rng.randf() < 0.28:
				target = 0.0                       # kelime arasi es
				next_toggle = t + rng.randf_range(0.09, 0.24)
			else:
				target = rng.randf_range(0.5, 1.0) # hece
				next_toggle = t + rng.randf_range(0.07, 0.19)
		amp += (target - amp) * 0.004
		var f := 122.0 + 18.0 * sin(t * 1.7) + 26.0 * amp * sin(t * 7.3)
		phase += TAU * f / float(rate)
		var v := 0.55 * sin(phase) + 0.28 * sin(2.0 * phase + 0.4) \
				+ 0.17 * sin(3.0 * phase + 1.1)
		lp += (rng.randf_range(-1.0, 1.0) - lp) * 0.18
		v = (v + lp * 0.35) * amp
		v = clampf(v * 1.5, -0.92, 0.92)           # radyo kompresyonu
		data.encode_s16(i * 2, int(v * 32767.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.data = data
	w.loop_mode = AudioStreamWAV.LOOP_FORWARD
	w.loop_end = n
	return w


func say(speaker: String, text: String, dur := 4.0) -> void:
	_queue.append([speaker, text, dur])
	if not _busy:
		_next()


func _next() -> void:
	if _queue.is_empty():
		_busy = false
		_lbl.text = ""
		_panel.visible = false
		_voice.stop()
		return
	_busy = true
	var it: Array = _queue.pop_front()
	_sp.play()
	# mirilti: replik suresince, her replikte farkli tonda ([ANONS] icin daha pes)
	_voice.pitch_scale = randf_range(0.55, 0.65) if str(it[0]).begins_with("[") \
			else randf_range(0.93, 1.07)
	_voice.play(randf_range(0.0, 4.0))
	_lbl.text = "%s  —  %s" % [it[0], it[1]]
	_panel.visible = true
	var tmr := get_tree().create_timer(float(it[2]))
	tmr.timeout.connect(func() -> void:
		_voice.stop()
		_next())
