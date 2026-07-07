extends CanvasLayer
## Telsis — MERKEZ'in sesi + CAGRI sistemi.
## Merkez kendiliginden konusmaz: once telsiz CALAR (sol altta ikon yanip soner
## + calma sesi), oyuncu Q ile "cevap verince" hat acilir ve replikler akar.
## KAYA (oyuncunun kendisi) ve [ANONS] cagri yapmaz — direkt calar.
## say() kuyruga ekler; VO eklenince ayni API kullanilir.

var _lbl: Label
var _panel: PanelContainer
var _queue: Array = []
var _busy := false
var _squelch_open: AudioStreamPlayer    # hat acilirken kisa squelch
var _squelch_close: AudioStreamPlayer   # hat kapanirken kisa squelch
var _hiss: AudioStreamPlayer            # iletim boyunca tasiyici hisirtisi (loop)
var _voice: AudioStreamPlayer           # anlamsiz telsiz konusmasi (tersten kayit)
var _voice_len := 0.0

# --- CAGRI SISTEMI ---
# durum: 0 IDLE (hat kapali), 1 RINGING (caliyor, Q bekleniyor), 2 ACTIVE (akiyor)
var _state := 0
var _line_established := false          # ilk temas sonrasi hat ACIK — Merkez
                                        # cagri yapmadan direkt konusur (gecikme yok)
var _ring: AudioStreamPlayer            # telsiz calma sesi (periyodik)
var _ring_box: HBoxContainer            # sol altta yanip sonen ikon + ipucu
var _ring_icon: TextureRect             # telsiz ikonu
var _ring_hint: Label                   # ikonun yaninda "[Q] Cevap ver"
var _ring_t := 0.0
var _ring_beep_t := 0.0


func _ready() -> void:
	# CCTV (16) ve examine (17) UZERINDE — altyazi/cagri o ekranlarda da gorunur
	layer = 20
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	# altyazi kutusu: yari saydam siyah panel, ortalanmis, alta yakin
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

	# --- sesler (gercek kayitlar) ---
	# squelch (two-way telsiz): tek dosyanin bas kismindan kisa parcalar calariz
	var squelch: AudioStream = load("res://assets/audio/radio_squelch.wav")
	_squelch_open = AudioStreamPlayer.new()
	_squelch_open.stream = squelch
	_squelch_open.volume_db = -15.0
	add_child(_squelch_open)
	_squelch_close = AudioStreamPlayer.new()
	_squelch_close.stream = squelch
	_squelch_close.volume_db = -18.0
	add_child(_squelch_close)

	# tasiyici hisirtisi: iletim ACIKKEN surekli, cok kisik bant gurultusu (sentez)
	_hiss = AudioStreamPlayer.new()
	_hiss.stream = _make_hiss()
	_hiss.volume_db = -36.0
	add_child(_hiss)

	# telsiz calma sesi (kullanicinin WalkieTalkie kaydi) — RINGING'de periyodik
	_ring = AudioStreamPlayer.new()
	_ring.stream = load("res://assets/audio/radio_ring.wav")
	_ring.volume_db = -12.0
	add_child(_ring)

	# telsiz konusma sesi: gercek telsiz kaydi TERSTEN — anlasilmaz ama "birisi
	# telsizden konusuyor" hissi. MERKEZ konusurken kisik, arka planda calar.
	_voice = AudioStreamPlayer.new()
	var vstream: AudioStream = load("res://assets/audio/radio_voice.wav")
	if vstream is AudioStreamWAV:
		(vstream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
		_voice_len = float((vstream as AudioStreamWAV).get_length())
	_voice.stream = vstream
	_voice.volume_db = -13.0     # konusma alt-dokusu (tersten telsiz) — duyulur ama bogyk
	add_child(_voice)

	# --- CAGRI UYARISI: sol altta yanip sonen telsiz ikonu + kisa ipucu ---
	var ring_box := HBoxContainer.new()
	ring_box.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	ring_box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	ring_box.offset_left = 40.0
	ring_box.offset_bottom = -40.0
	ring_box.add_theme_constant_override("separation", 16)
	ring_box.alignment = BoxContainer.ALIGNMENT_CENTER
	ring_box.visible = false
	root.add_child(ring_box)
	_ring_icon = TextureRect.new()
	_ring_icon.texture = load("res://assets/ui/radio_icon.png")
	_ring_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_ring_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_ring_icon.custom_minimum_size = Vector2(78, 205)
	ring_box.add_child(_ring_icon)
	_ring_hint = Label.new()
	_ring_hint.add_theme_font_override("font", load("res://assets/fonts/Barlow-SemiBold.ttf"))
	_ring_hint.add_theme_font_size_override("font_size", 24)
	_ring_hint.add_theme_color_override("font_color", Color(0.7, 0.95, 0.78))
	_ring_hint.add_theme_color_override("font_outline_color", Color(0, 0.02, 0.02, 0.9))
	_ring_hint.add_theme_constant_override("outline_size", 5)
	_ring_hint.text = "[Q]  Cevap ver"
	_ring_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ring_box.add_child(_ring_hint)
	_ring_box = ring_box


## Tasiyici hisirtisi: iletim boyunca calan cok kisik, dar-bant "ssss" (loop)
func _make_hiss() -> AudioStreamWAV:
	var rate := 16000
	var n := rate  # 1 sn loop
	var data := PackedByteArray()
	data.resize(n * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 13
	var lp := 0.0
	for i in n:
		lp += (rng.randf_range(-1.0, 1.0) - lp) * 0.35
		var v := lp * 0.5
		data.encode_s16(i * 2, int(clampf(v, -1.0, 1.0) * 32767.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.data = data
	w.loop_mode = AudioStreamWAV.LOOP_FORWARD
	w.loop_end = n
	return w


## Kisa squelch cal (dosyanin basindan; sure sonra kes)
func _play_squelch(p: AudioStreamPlayer, dur: float, pitch := 1.0) -> void:
	p.pitch_scale = pitch
	p.play(0.0)
	get_tree().create_timer(dur).timeout.connect(func() -> void:
		if p.playing:
			p.stop())


## Bir replik cagri gerektirir mi? KAYA (oyuncunun kendisi) ve [ANONS]
## cagri yapmaz — direkt calar. Digerleri (MERKEZ, EDA, CAVIT) once telsizi
## CALDIRIR; oyuncu Q ile cevap verince hat acilir. (Blok KAYA ile baslarsa
## "biz telsizi kullaniyoruz" demektir — cagri gelmez.)
func _needs_answer(speaker: String) -> bool:
	# hat bir kez kuruldu mu (Sekans 1 ilk cevap): artik cagri YOK, direkt akar.
	# Boylece prosedur/vardiya replikleri Q beklemez, gecikmesiz sirayla gelir.
	if _line_established:
		return false
	return speaker != "BEN" and not speaker.begins_with("[")


## dur <= 0: sure metin uzunlugundan otomatik hesaplanir (okuma hizi ~14 krk/sn).
func say(speaker: String, text: String, dur := 0.0) -> void:
	var auto := clampf(1.6 + 0.068 * float(text.length()), 2.6, 10.0)
	_queue.append([speaker, text, maxf(dur, auto)])
	if _state == 0:
		if _needs_answer(str(_queue[0][0])):
			_start_ringing()
		else:
			_state = 2
			_next()


## is_busy: cagri caliyor ya da replik akiyorsa mesgul (sekans akisi bekler)
func is_busy() -> bool:
	return _state != 0


## Hatti kalici ac (Sekans 1 sonrasi): Merkez artik cagri yapmadan direkt konusur
func establish_line() -> void:
	_line_established = true


## Telsiz calmaya baslar (cagri gelir, Q beklenir)
func _start_ringing() -> void:
	_state = 1
	_ring_t = 0.0
	_ring_beep_t = 0.0
	_ring.play()
	if _ring_box:
		_ring_box.visible = true


## Oyuncu Q ile cevap verdi: hat acilir, replikler akmaya baslar
func answer() -> void:
	if _state != 1:
		return
	_line_established = true      # hat kuruldu — bundan sonra Merkez direkt konusur
	_ring.stop()
	if _ring_box:
		_ring_box.visible = false
	_state = 2
	_next()


func _process(delta: float) -> void:
	if _state != 1:
		return
	_ring_t += delta
	# ikon + ipucu birlikte yanip soner
	if _ring_box:
		var a := 0.4 + 0.6 * (0.5 + 0.5 * sin(_ring_t * 6.5))
		_ring_box.modulate.a = a
	# calma sesi periyodik (0.83 sn kayit + ~0.9 sn ara)
	_ring_beep_t += delta
	if _ring_beep_t >= 1.75:
		_ring_beep_t = 0.0
		if not _ring.playing:
			_ring.play()


## Q tusu: telsizi cevapla (yalniz caliyorken)
func _unhandled_input(event: InputEvent) -> void:
	if _state == 1 and event is InputEventKey and event.pressed \
			and not event.echo and event.physical_keycode == KEY_Q:
		answer()
		get_viewport().set_input_as_handled()


func _next() -> void:
	if _queue.is_empty():
		_state = 0
		_busy = false
		_lbl.text = ""
		_panel.visible = false
		_hiss.stop()
		_voice.stop()
		return
	_busy = true
	var it: Array = _queue.pop_front()
	var spk := str(it[0])
	# BEN = oyuncunun kendisi (telsize konusur): kisa squelch, hisirti/ses yok
	var is_self := spk == "BEN"
	_play_squelch(_squelch_open, 0.5, 1.0 if not is_self else 1.12)
	if not is_self:
		_hiss.play()
		# anlamsiz telsiz konusmasi: kaydin rastgele noktasindan, replik pes/tiz
		_voice.pitch_scale = randf_range(0.94, 1.06) if not spk.begins_with("[") \
				else randf_range(0.6, 0.72)
		_voice.play(randf_range(0.0, maxf(_voice_len - 10.0, 0.0)))
	else:
		_hiss.stop()
		_voice.stop()
	_lbl.text = "%s  —  %s" % [spk, it[1]]
	_panel.visible = true
	var tmr := get_tree().create_timer(float(it[2]))
	tmr.timeout.connect(func() -> void:
		_hiss.stop()
		_voice.stop()
		_play_squelch(_squelch_close, 0.32, 1.15)   # iletim biter: kisa squelch
		_next())
