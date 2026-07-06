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

# ---- ust hol olculeri (turnikeli giris holu — Bolum 0/1 mekani) ----
const HALL_Z1 := -22.5                  # kuzey duvar (kepenkli cikis)
const HALL_HW := 8.5                    # yari genislik
const HALL_H := 3.2                     # tavan yuksekligi (zeminden)

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
var _tension_inst: AudioEffectSpectrumAnalyzerInstance
var _tension_lvl := 0.0
var _post_mat: ShaderMaterial
var _train_wav: AudioStream
var _whisper_stream: AudioStream
var _switch_lever: MeshInstance3D
var _switch_done := false
var _plat_lights: Array = []
var _aux_lights: Array = []              # cukur/tunel/kafes isiklari (karartmada soner)
var _scare: Node3D                       # golge figur (gec asamada aktiflesir)
var _blackout_busy := false
# gorev zinciri: 0 salter, 1 turnike tara, 2 T-3 bulundu, 3 anons+Yolcu,
# 4 sol uc gorevi (karartma kurulu), 5 karartma oldu, 6 telefon caldi
var _quest := 0
var _anomaly_notified := false
var _yolcu_notified := false
var _yolcu: Node3D
var _yolcu_mats: Array[ShaderMaterial] = []
var _yolcu_gone := false


## Ilk gorev tamam: salter kalkar; MERKEZ kisa bir gecikmeyle fark eder
## (karsi tarafta "panoya bakti, gordu" hissi), sonra yeni gorevi verir
func _on_panel_switch() -> void:
	if _switch_done:
		return
	_switch_done = true
	var tw := create_tween()
	tw.tween_property(_switch_lever, "rotation:x", deg_to_rad(-35.0), 0.16)
	get_tree().create_timer(1.8).timeout.connect(func() -> void:
		var r := get_tree().get_first_node_in_group("radio")
		if r:
			r.call("say", "MERKEZ", "...Gördüm. Besleme geldi. İyi iş.", 3.5)
			r.call("say", "MERKEZ",
					"Sıradaki iş yukarıda. Hole çık — turnikelerden gece sinyali alamıyorum. Beşi de ölü görünüyor.", 7.0)
			r.call("say", "MERKEZ",
					"Terminalini aç, TARAMA modu. Beşini de tek tek doğrula bana.", 5.0)
		var term := get_tree().get_first_node_in_group("terminal")
		if term:
			term.call("add_log", "TAMAM> A panosu beslemede")
			term.call("add_log", "GÖREV> üst hol: turnikeleri tara")
		_quest = 1)


## Terminal T-3'u taradi (UYUMSUZ): MERKEZ gecistirir — ilk catlak
func on_anomaly_scanned(_n: Node) -> void:
	if _quest != 1 or _anomaly_notified:
		return
	_anomaly_notified = true
	_quest = 2
	get_tree().create_timer(1.2).timeout.connect(func() -> void:
		var r := get_tree().get_first_node_in_group("radio")
		if r:
			r.call("say", "MERKEZ", "...Ne çıktı?", 2.4)
			r.call("say", "MERKEZ", "T-üç mü? ...Dur, bakıyorum.", 3.5)
			r.call("say", "MERKEZ",
					"...Boşver onu. Eski arıza, kartı çürük. Kayda geçme.", 4.5)
			r.call("say", "MERKEZ", "Diğerleri temizse işin bitti orada.", 3.5)
		var term := get_tree().get_first_node_in_group("terminal")
		if term:
			term.call("add_log", "TARAMA> T-3: UYUMSUZ (kayıt: düşülmedi)")
		get_tree().create_timer(11.0).timeout.connect(_anons_event))


## Bozuk anons: hoparlorden pes, anlasilmaz ses — ayni durak uc kez
func _anons_event() -> void:
	var sp := AudioStreamPlayer3D.new()
	sp.stream = _whisper_stream
	sp.volume_db = -3.0
	sp.pitch_scale = 0.5
	sp.unit_size = 5.0
	sp.max_distance = 40.0
	sp.position = Vector3(0, TOP_Y + 2.8, -16.0)
	add_child(sp)
	sp.play(randf_range(5.0, 20.0))
	get_tree().create_timer(8.0).timeout.connect(func() -> void:
		sp.queue_free())
	var r := get_tree().get_first_node_in_group("radio")
	if r:
		r.call("say", "[ANONS]",
				"Bir sonraki tren: Hisar-yedi... Hisar-yedi... Hisar-yedi...", 7.0)
		r.call("say", "MERKEZ", "...Bu anonsu ben çalmadım.", 3.5)
		r.call("say", "MERKEZ", "Sistem eski. Kayıt takılmıştır, o kadar. Perona in sen.", 5.0)
	var term := get_tree().get_first_node_in_group("terminal")
	if term:
		term.call("add_log", "GÖREV> perona dön")
	_quest = 3
	_spawn_yolcu()
	# fisiltilar ancak bu andan itibaren baslar (anons bir seyi "uyandirdi")
	if _whisper_stream != null:
		_schedule_whisper(randf_range(45.0, 80.0))


## Yolcu: bankta oturan, nefes almayan figur (CLAUDE.md Bolum 1).
## Taranirsa OKUNAMIYOR; cok yaklasinca fisiltiyla kaybolur.
func _spawn_yolcu() -> void:
	var wraith: Shader = load("res://shaders/wraith.gdshader")
	_yolcu = Node3D.new()
	_yolcu.position = Vector3(-9.55, 0.46, 0.42)   # sol bank oturagi (oturak ~0.45 m)
	_yolcu.rotation.y = 0.3                         # hafif "yanlis" acida oturur
	var parts := [
		# [radius, height, pos, rot_x_deg, phase]
		[0.11, 0.26, Vector3(0.0, 0.76, 0.02), 0.0, 0.3],      # kafa
		[0.165, 0.60, Vector3(0.0, 0.36, 0.0), 7.0, 1.2],      # govde (hafif one egik)
		[0.055, 0.50, Vector3(-0.17, 0.38, 0.03), 12.0, 2.0],  # sol kol (govdeye bitisik)
		[0.055, 0.50, Vector3(0.17, 0.38, 0.03), 12.0, 3.1],   # sag kol
		[0.075, 0.40, Vector3(-0.10, 0.05, 0.20), 90.0, 4.0],  # sol uyluk (one yatay)
		[0.075, 0.40, Vector3(0.10, 0.05, 0.20), 90.0, 5.2],   # sag uyluk
		[0.06, 0.44, Vector3(-0.10, -0.22, 0.38), 8.0, 4.6],   # sol baldir (yere iner)
		[0.06, 0.44, Vector3(0.10, -0.22, 0.38), 8.0, 5.7],    # sag baldir
	]
	for s in parts:
		var mi := MeshInstance3D.new()
		var cap := CapsuleMesh.new()
		cap.radius = s[0]
		cap.height = s[1]
		cap.radial_segments = 20
		cap.rings = 10
		mi.mesh = cap
		var m := ShaderMaterial.new()
		m.shader = wraith
		m.set_shader_parameter("phase", s[4])
		m.set_shader_parameter("solidity", 0.86)
		m.set_shader_parameter("alpha_mul", 1.0)
		_yolcu_mats.append(m)
		mi.material_override = m
		mi.position = s[2]
		mi.rotation.x = deg_to_rad(float(s[3]))
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_yolcu.add_child(mi)
	# tarama icin govde collider'i (OKUNAMIYOR)
	var yb := StaticBody3D.new()
	yb.add_to_group("unreadable")
	var yc := CollisionShape3D.new()
	var ys := SphereShape3D.new()
	ys.radius = 0.5
	yc.shape = ys
	yc.position = Vector3(0, 0.45, 0.1)
	yb.add_child(yc)
	_yolcu.add_child(yb)
	add_child(_yolcu)


## Yolcu taranirsa MERKEZ'in "manken" yalani (bir kez)
func on_yolcu_scanned(_n: Node) -> void:
	if _yolcu_notified:
		return
	_yolcu_notified = true
	get_tree().create_timer(1.0).timeout.connect(func() -> void:
		var r := get_tree().get_first_node_in_group("radio")
		if r:
			r.call("say", "MERKEZ", "Dur— ...o mu? Manken o, manken. Depo malı.", 4.5)
			r.call("say", "MERKEZ", "Yaklaşma istersen. Devrilirse tutanak yazarız, uğraşamam.", 5.0))


## Cok yaklasinca Yolcu fisiltiyla kaybolur; MERKEZ inkar eder
func _vanish_yolcu() -> void:
	_yolcu_gone = true
	var sp := AudioStreamPlayer3D.new()
	sp.stream = _whisper_stream
	sp.volume_db = -6.0
	sp.pitch_scale = 0.8
	sp.max_distance = 10.0
	sp.position = _yolcu.global_position + Vector3(0, 1.0, 0)
	add_child(sp)
	sp.play(randf_range(0.0, 30.0))
	get_tree().create_timer(2.2).timeout.connect(func() -> void:
		sp.queue_free())
	var tw := create_tween()
	tw.tween_method(func(a: float) -> void:
		for m in _yolcu_mats:
			m.set_shader_parameter("alpha_mul", a), 1.0, 0.0, 0.45)
	tw.tween_callback(func() -> void:
		_yolcu.queue_free()
		_yolcu = null)
	get_tree().create_timer(2.5).timeout.connect(func() -> void:
		var r := get_tree().get_first_node_in_group("radio")
		if r:
			r.call("say", "MERKEZ", "...Nefesin değişti. Ne oldu orada?", 3.5)
			r.call("say", "MERKEZ", "Beni dinle. Peronda senden başka kimse yok. Yok.", 5.0)
			r.call("say", "MERKEZ", "...Anlaşıldı mı? Devam.", 3.0))
	# bir sonraki halka: MERKEZ oyuncuyu peronun sol ucuna yollar (karartma orada kurulu)
	get_tree().create_timer(18.0).timeout.connect(func() -> void:
		var r := get_tree().get_first_node_in_group("radio")
		if r:
			r.call("say", "MERKEZ",
					"...Peki. Son bir iş kaldı: peronun sol ucu, ankesörün orada B panosu var.", 6.0)
			r.call("say", "MERKEZ", "Göstergeyi oku bana. Sonra çıkış evrakını hazırlıyorum.", 4.5)
		var term := get_tree().get_first_node_in_group("terminal")
		if term:
			term.call("add_log", "GÖREV> sol uç: B panosu göstergesi")
		_quest = 4)


## Blackout korkutmasi: peronun sol ucuna gidince uzakta kapi carpar,
## isiklar uzaktan yakina TEKER TEKER soner; karanlikta MERKEZ seslenir.
## Rolenin "cat" sesi: her lamba sonerken kendi konumundan duyulur
func _make_clack() -> AudioStreamWAV:
	var rate := 16000
	var n := int(rate * 0.12)
	var data := PackedByteArray()
	data.resize(n * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in n:
		var t := float(i) / float(rate)
		var env := exp(-t * 55.0)
		var v := (sin(TAU * 132.0 * t) * 0.6 + rng.randf_range(-1.0, 1.0) * 0.45) * env
		data.encode_s16(i * 2, int(clampf(v, -1.0, 1.0) * 32767.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.data = data
	return w


func _trigger_blackout() -> void:
	if _blackout_busy:
		return
	_blackout_busy = true
	var slam: AudioStream = load("res://assets/audio/close_door.wav")
	if slam != null:
		var sp := AudioStreamPlayer3D.new()
		sp.stream = slam
		sp.volume_db = -2.0
		sp.max_distance = 60.0
		sp.unit_size = 5.0
		sp.position = Vector3(PLAT_L - 0.5, 2.0, 3.0)
		add_child(sp)
		sp.play()
		sp.finished.connect(sp.queue_free)
	await get_tree().create_timer(1.6).timeout
	# uzaktan (sag uc) oyuncuya dogru TEKER TEKER sonme; her lambada role sesi
	var clack := _make_clack()
	for i in range(_plat_lights.size() - 1, -1, -1):
		var lt := _plat_lights[i] as Node
		lt.set("blackout", true)
		var cp := AudioStreamPlayer3D.new()
		cp.stream = clack
		cp.volume_db = -3.0
		cp.unit_size = 4.0
		cp.max_distance = 45.0
		cp.position = ((lt as Node3D).get_parent() as Node3D).position
		add_child(cp)
		cp.play()
		cp.finished.connect(cp.queue_free)
		await get_tree().create_timer(0.55).timeout
	# yardimci isiklar da gider — tam karanlik
	for a in _aux_lights:
		(a as Node3D).visible = false
	await get_tree().create_timer(4.0).timeout
	var r := get_tree().get_first_node_in_group("radio")
	if r:
		r.call("say", "MERKEZ", "...Pano düştü. Hisar-yedi? Orada mısın? Cevap ver.", 5.0)
	await get_tree().create_timer(2.5).timeout
	for lt in _plat_lights:
		(lt as Node).set("blackout", false)
	for a in _aux_lights:
		(a as Node3D).visible = true
	if r:
		r.call("say", "MERKEZ", "...Geldi mi ışıklar? Tamam. Tamam, iyi.", 4.0)
		r.call("say", "MERKEZ", "Eski bina dedim ya. ...B panosunu boşver şimdi. Olduğun yerde bekle.", 5.5)
	_quest = 5
	# zincirin devami: az sonra ankesorlu telefon calar (oyuncu hala o uctayken)
	get_tree().create_timer(randf_range(14.0, 22.0)).timeout.connect(_phone_ring_event)
	await get_tree().create_timer(180.0).timeout
	_blackout_busy = false


## Ankesorlu telefon bir kez caldi mi? (tek seferlik tekinsiz olay)
var _phone_rang := false


func _make_ring() -> AudioStreamWAV:
	var rate := 16000
	var n := int(rate * 1.3)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var t := float(i) / float(rate)
		var trem := 0.5 + 0.5 * sin(TAU * 21.0 * t)
		var v := (0.6 * sin(TAU * 425.0 * t) + 0.25 * sin(TAU * 850.0 * t)) * trem
		v *= minf(t / 0.02, 1.0) * minf((1.3 - t) / 0.06, 1.0)
		data.encode_s16(i * 2, int(clampf(v * 0.8, -1.0, 1.0) * 32767.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.data = data
	return w


## Telefon calar (4 kez), kimse acamadan susar; MERKEZ: "o hat yillardir kesik"
func _phone_ring_event() -> void:
	if _phone_rang:
		return
	_phone_rang = true
	var ring := _make_ring()
	var sp := AudioStreamPlayer3D.new()
	sp.stream = ring
	sp.volume_db = -4.0
	sp.max_distance = 30.0
	sp.position = Vector3(-12.55, 1.4, 0.25)
	add_child(sp)
	for i in 4:
		sp.play()
		await get_tree().create_timer(2.6).timeout
	sp.queue_free()
	await get_tree().create_timer(2.0).timeout
	var r := get_tree().get_first_node_in_group("radio")
	if r:
		r.call("say", "MERKEZ", "...O ses neydi? Telefon mu çaldı?", 3.5)
		r.call("say", "MERKEZ", "O hat on bir yıldır kesik evladım.", 4.0)
		r.call("say", "MERKEZ", "...Açmadın, değil mi?", 3.0)
	_quest = 6
	# bundan sonra golge figur silahlanabilir (peron ucu + arkani donme korkutmasi)
	get_tree().create_timer(25.0).timeout.connect(func() -> void:
		if _scare:
			_scare.set("enabled", true))


## Olay tetikleyicileri
func _build_events() -> void:
	# blackout: peronun SOL ucu (ankesorlu telefon tarafi)
	var area := Area3D.new()
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(2.6, 3.0, PLAT_D)
	cs.shape = bs
	cs.position = Vector3(-PLAT_L + 1.3, 1.5, PLAT_D * 0.5)
	area.add_child(cs)
	area.body_entered.connect(func(b: Node3D) -> void:
		if b is CharacterBody3D and _quest >= 4:
			_trigger_blackout())
	add_child(area)


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


## Uzak "hayalet tren" gecisi (sentez: kahverengi gurultu rumble + ray klaklari,
## icine islenmis gel-git zarfi). Arka plan is parcaciginda uretilir (aciliste takilma olmasin).
func _make_train() -> AudioStreamWAV:
	var rate := 16000
	var dur := 22.0
	var n := int(rate * dur)
	var data := PackedByteArray()
	data.resize(n * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	var brown := 0.0
	var lp := 0.0
	var cl_lp := 0.0
	for i in n:
		var t := float(i) / float(rate)
		var u := t / dur
		# zarf: yavas yaklasir (tepe ~%45), gecer, soner
		var env := smoothstep(0.0, 0.45, u) * (1.0 - smoothstep(0.55, 1.0, u))
		env = pow(env, 1.5)
		# derin rumble: entegre gurultu + alcak gecis
		brown = clampf(brown + rng.randf_range(-0.02, 0.02), -1.0, 1.0) * 0.998
		lp += (brown - lp) * 0.07
		var v := lp * 2.4
		# ray klaklari: ~1.3 Hz cift vurus (da-dum), uzakligin yumusakligi
		var ph := fmod(t * 1.3, 1.0)
		var cl := 0.0
		if ph < 0.06:
			cl = exp(-ph * 80.0)
		elif ph > 0.11 and ph < 0.17:
			cl = 0.8 * exp(-(ph - 0.11) * 80.0)
		cl_lp += (rng.randf_range(-1.0, 1.0) * cl - cl_lp) * 0.22
		v += cl_lp * 0.75
		v = clampf(v * env, -0.95, 0.95)
		data.encode_s16(i * 2, int(v * 32767.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.stereo = false
	w.data = data
	return w


func _train_ready(w: AudioStream) -> void:
	_train_wav = w
	_schedule_train(randf_range(110.0, 170.0))  # ilk tren: acilis sakin kalsin


func _schedule_train(wait: float) -> void:
	get_tree().create_timer(wait).timeout.connect(_play_train)


## Treni ray cukurunda bir uctan digerine "gecir" — 3D pan + bakilan yone gore
## dogal yaklasma/uzaklasma. Tren asla gorunmez (hayalet tren).
func _play_train() -> void:
	if _train_wav == null:
		return
	var dirn := 1.0 if randf() < 0.5 else -1.0
	var sp := AudioStreamPlayer3D.new()
	sp.stream = _train_wav
	sp.volume_db = -6.0
	sp.unit_size = 4.0
	sp.max_distance = 70.0
	sp.pitch_scale = randf_range(0.93, 1.03)
	var dur := _train_wav.get_length() / sp.pitch_scale
	# uzun gercek kayitta yavas suzulme, kisa sentezde tam gecis
	var span := 42.0 if dur < 26.0 else 26.0
	sp.position = Vector3(-dirn * span, 1.2, (PIT_Z0 + PIT_Z1) * 0.5)
	add_child(sp)
	sp.play()
	var tw := create_tween()
	tw.tween_property(sp, "position:x", dirn * span, dur)
	tw.tween_callback(func() -> void:
		sp.queue_free()
		_schedule_train(randf_range(70.0, 160.0)))


func _schedule_whisper(wait: float) -> void:
	get_tree().create_timer(wait).timeout.connect(_play_whisper)


## Fisilti: oyuncunun yakininda rastgele bir yonden, kayittan rastgele bir dilim.
## Kisa surer, sonra sonerek kaybolur — "birileri konusuyor muydu?" hissi.
func _play_whisper() -> void:
	if _whisper_stream == null:
		return
	var p := get_tree().get_first_node_in_group("player") as Node3D
	var sp := AudioStreamPlayer3D.new()
	sp.stream = _whisper_stream
	sp.volume_db = -14.0
	sp.unit_size = 1.6
	sp.max_distance = 12.0
	sp.pitch_scale = randf_range(0.88, 1.0)
	var ang := randf() * TAU
	var base := p.global_position if p else Vector3(0, 0, 4)
	sp.position = base + Vector3(cos(ang) * 3.5, 1.4, sin(ang) * 3.5)
	add_child(sp)
	sp.play(randf_range(0.0, maxf(_whisper_stream.get_length() - 10.0, 0.0)))
	var tw := create_tween()
	tw.tween_interval(randf_range(4.5, 8.0))
	tw.tween_property(sp, "volume_db", -46.0, 2.5)
	tw.tween_callback(func() -> void:
		sp.queue_free()
		_schedule_whisper(randf_range(60.0, 140.0)))


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
	_build_upper_hall()
	_build_office()
	_build_platform()
	_build_props()
	_build_rails()
	_build_lights()
	_build_environment()
	_build_audio()
	_build_post_fx()
	_spawn_player()
	_build_pause_menu()
	_build_radio()
	_build_events()
	_build_cctv()
	_build_intro()
	add_to_group("quest_mgr")
	_maybe_screenshot()


## Telsis + acilis replikleri (MERKEZ vardiyayi baslatir, ilk gorevi verir)
func _build_radio() -> void:
	var r := CanvasLayer.new()
	r.set_script(load("res://scripts/radio.gd"))
	r.add_to_group("radio")
	add_child(r)
	# acilis: once karanlik + baslik (intro); MERKEZ acele etmez, dogal telsiz dili
	get_tree().create_timer(14.0).timeout.connect(func() -> void:
		r.call("say", "MERKEZ", "Hisar-yedi, Hisar-yedi. Merkez konuşuyor. Duyuyorsan söyle.", 5.5)
		r.call("say", "MERKEZ", "...Tamam, sinyalin geldi. İyi.", 3.5)
		r.call("say", "MERKEZ",
				"Gece vardiyası sende evladım. Ben buradayım, kanal hep açık.", 5.5)
		r.call("say", "MERKEZ",
				"Acele etme. Masandaki terminali ve feneri üstüne al — ikisi de zimmetli.", 6.0))
	get_tree().create_timer(42.0).timeout.connect(func() -> void:
		r.call("say", "MERKEZ", "Hazırsan başlıyoruz. Ofisten çık, hole geç.", 4.5)
		r.call("say", "MERKEZ",
				"Merdivenden peron katına in. Duvarda A yazan pano var — kapağındaki ana şalteri kaldır.", 6.5)
		r.call("say", "MERKEZ", "Basit iş. Yapınca söyle.", 3.0)
		var term := get_tree().get_first_node_in_group("terminal")
		if term:
			term.call("add_log", "GÖREV> peron katı: A panosu şalteri"))


## Guvenlik kamerasi sistemi (ofisteki bilgisayardan acilir)
func _build_cctv() -> void:
	var c := Node.new()
	c.set_script(load("res://scripts/cctv.gd"))
	add_child(c)


## Acilis karti: siyah ekran + istasyon adi, yavasca acilir (oyun hissi)
func _build_intro() -> void:
	var cl := CanvasLayer.new()
	cl.layer = 30
	add_child(cl)
	var black := ColorRect.new()
	black.color = Color(0, 0, 0, 1)
	black.set_anchors_preset(Control.PRESET_FULL_RECT)
	black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cl.add_child(black)
	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_CENTER)
	vb.grow_horizontal = Control.GROW_DIRECTION_BOTH
	vb.grow_vertical = Control.GROW_DIRECTION_BOTH
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	black.add_child(vb)
	var t1 := Label.new()
	t1.text = "H İ S A R — 7"
	t1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t1.add_theme_font_override("font",
			load("res://assets/fonts/BarlowCondensed-SemiBold.ttf"))
	t1.add_theme_font_size_override("font_size", 78)
	t1.add_theme_color_override("font_color", Color(0.78, 0.82, 0.8))
	vb.add_child(t1)
	var t2 := Label.new()
	t2.text = "gece vardiyası — 03:47"
	t2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t2.add_theme_font_override("font", load("res://assets/fonts/Barlow-Medium.ttf"))
	t2.add_theme_font_size_override("font_size", 26)
	t2.add_theme_color_override("font_color", Color(0.5, 0.54, 0.52))
	vb.add_child(t2)
	t1.modulate.a = 0.0
	t2.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_interval(0.8)
	tw.tween_property(t1, "modulate:a", 1.0, 1.6)
	tw.parallel().tween_property(t2, "modulate:a", 1.0, 2.2)
	tw.tween_interval(3.2)
	tw.tween_property(vb, "modulate:a", 0.0, 1.4)
	tw.tween_property(black, "color:a", 0.0, 3.0)
	tw.tween_callback(cl.queue_free)


# Gerilim muziginin anlik enerjisi → ekran kenari kararmasi.
# Ses yogunlasirken yavas kararir, kesilince biraz daha hizli acilir.
const TENSION_DB_FLOOR := -46.0
const TENSION_DB_CEIL := -37.0

func _process(delta: float) -> void:
	# Yolcu: cok yaklasinca kaybolur
	if _yolcu != null and not _yolcu_gone:
		var pl := get_tree().get_first_node_in_group("player") as Node3D
		if pl and pl.global_position.distance_to(_yolcu.global_position) < 1.8:
			_vanish_yolcu()
	if _tension_inst == null or _post_mat == null:
		return
	var mag := _tension_inst.get_magnitude_for_frequency_range(30.0, 2600.0).length()
	var db := linear_to_db(maxf(mag, 0.00001))
	var target := clampf((db - TENSION_DB_FLOOR) / (TENSION_DB_CEIL - TENSION_DB_FLOOR),
			0.0, 1.0)
	var rate := 0.8 if target > _tension_lvl else 1.7
	_tension_lvl = lerpf(_tension_lvl, target, 1.0 - exp(-rate * delta))
	_post_mat.set_shader_parameter("tension_dark", _tension_lvl * 0.62)


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
	# merdiven oncesi duzluk: hol zeminiyle AYNI fayans (koyu tas "kuyu" gibi okunuyordu)
	_box(Vector3(W, 0.3, F2_END_Z - STAIR_END_Z),
			Vector3(0, TOP_Y - 0.15, (F2_END_Z + STAIR_END_Z) * 0.5), mat_floor_tile)
	# merdiven agzi sari ikaz bandi
	_box(Vector3(W - 0.5, 0.012, 0.4),
			Vector3(0, TOP_Y + 0.006, F2_END_Z - 0.26), mat_tactile, false)

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
	# hol guney duvarina girmeden biter (-10.58) — es duzlem titremesi olmasin
	_box(Vector3(0.3, wall_h, 10.48),
			Vector3(-HW - 0.15, wall_cy, -5.34), mat_white_tile)
	_box(Vector3(0.3, wall_h, 10.48),
			Vector3(HW + 0.15, wall_cy, -5.34), mat_marble_tile)
	# merdiven agzi kose kolonlari (pilaster): duvar yuzeylerinden TASKIN olmali
	# (es duzlemde kalirsa kosede model bozulmasi / titreme olusur)
	for side in [-1.0, 1.0]:
		_box(Vector3(0.5, wall_h, 0.5), Vector3(side * (HW + 0.08), wall_cy, -0.075),
				mat_marble_tile)
		_box(Vector3(0.53, 0.36, 0.53), Vector3(side * (HW + 0.08), 0.18, -0.075),
				mat_dark_tile, false)
	# ust kat sonu artik duvar degil — turnikeli ust hole acilir (_build_upper_hall)

	# tavanlar: DUZ ve FERAH — egim yok, iki yuksek kademe + boyali gecis bantlari
	_box(Vector3(W + 0.6, 0.3, 1.35), Vector3(0, CEIL_Y + 0.14, -0.55), mat_stucco, false)
	# agiz gecis bandi (peron 3.5 -> merdiven 4.35)
	_box(Vector3(W + 0.6, 1.06, 0.15), Vector3(0, 3.92, -1.13), mat_paint, false)
	# 1. kademe: alt kol + duzluk uzeri duz tavan (4.35)
	_box(Vector3(W + 0.6, 0.3, 3.25), Vector3(0, 4.5, -2.82), mat_stucco, false)
	# 2. gecis bandi (4.35 -> 5.75)
	_box(Vector3(W + 0.6, 1.55, 0.15), Vector3(0, 5.08, -4.47), mat_paint, false)
	# 2. kademe: ust kol uzeri duz tavan (5.75) — hol lentosuna girmeden biter
	# (lento ile ayni y-duzleminde ustuste binerse titreme olusur)
	_box(Vector3(W + 0.6, 0.3, 6.16),
			Vector3(0, 5.9, -7.5), mat_stucco, false)


# ------------------------------------------------------------------ ust hol

## Turnikeli ust hol: merdivenin ciktigi karanlik koridorun devami.
## Kepenkli (kapali) cikis, turnike sirasi, olu/donuk aydinlatma.
func _build_upper_hall() -> void:
	var y0 := TOP_Y                     # zemin ust yuzu
	var cy := y0 + HALL_H * 0.5
	var z0 := STAIR_END_Z               # guney (koridor agzi)

	# zemin + tavan
	_box(Vector3(HALL_HW * 2.0, 0.3, z0 - HALL_Z1),
			Vector3(0, y0 - 0.15, (z0 + HALL_Z1) * 0.5), mat_floor_tile)
	_box(Vector3(HALL_HW * 2.0, 0.3, z0 - HALL_Z1),
			Vector3(0, y0 + HALL_H + 0.15, (z0 + HALL_Z1) * 0.5), mat_soffit, false)

	# guney duvar: koridor agzinin iki yani + lento
	for side in [-1.0, 1.0]:
		var wsw := HALL_HW - HW
		_box(Vector3(wsw, HALL_H, 0.3),
				Vector3(side * (HW + wsw * 0.5), cy, z0 + 0.15), mat_white_tile)
	# koridor agzi ustu lento — alt yuzu merdiven tavanindan 3 cm asagida
	# (5.75'te es duzlem = titreme)
	_box(Vector3(W + 0.6, y0 + HALL_H - 5.72, 0.3),
			Vector3(0, 5.72 + (y0 + HALL_H - 5.72) * 0.5, z0 + 0.15), mat_paint, false)

	# kuzey duvar: kepenkli cikis ortada
	var shutter_w := 4.2
	for side in [-1.0, 1.0]:
		var wsn := HALL_HW - shutter_w * 0.5
		_box(Vector3(wsn, HALL_H, 0.3),
				Vector3(side * (shutter_w * 0.5 + wsn * 0.5), cy, HALL_Z1 - 0.15),
				mat_white_tile)
	# kepenk ustu bant
	_box(Vector3(shutter_w, HALL_H - 2.45, 0.3),
			Vector3(0, y0 + 2.45 + (HALL_H - 2.45) * 0.5, HALL_Z1 - 0.15), mat_paint)

	# dogu duvari (tam)
	_box(Vector3(0.3, HALL_H, z0 - HALL_Z1),
			Vector3(HALL_HW + 0.15, cy, (z0 + HALL_Z1) * 0.5), mat_marble_tile)
	# bati duvari: teknisyen ofisinin kapisi icin bosluklu (z -12.5..-13.6)
	var dz0 := -12.5
	var dz1 := -13.6
	_box(Vector3(0.3, HALL_H, z0 - dz0),
			Vector3(-HALL_HW - 0.15, cy, (z0 + dz0) * 0.5), mat_white_tile)
	_box(Vector3(0.3, HALL_H, dz1 - HALL_Z1),
			Vector3(-HALL_HW - 0.15, cy, (dz1 + HALL_Z1) * 0.5), mat_white_tile)
	_box(Vector3(0.3, HALL_H - 2.1, dz0 - dz1),
			Vector3(-HALL_HW - 0.15, y0 + 2.1 + (HALL_H - 2.1) * 0.5, (dz0 + dz1) * 0.5),
			mat_white_tile)
	# kapi kasasi (koyu boyali celik)
	var frm := StandardMaterial3D.new()
	frm.albedo_color = Color(0.16, 0.19, 0.2)
	frm.metallic = 0.4
	frm.roughness = 0.5
	for fz in [dz0, dz1]:
		_box(Vector3(0.34, 2.14, 0.07), Vector3(-HALL_HW - 0.15, y0 + 1.07, fz), frm, false)
	_box(Vector3(0.34, 0.07, dz0 - dz1 + 0.07),
			Vector3(-HALL_HW - 0.15, y0 + 2.135, (dz0 + dz1) * 0.5), frm, false)
	# kapi ustu tabela
	var olbl := Label3D.new()
	olbl.text = "TEKNİK SERVİS"
	olbl.font_size = 30
	olbl.pixel_size = 0.0013
	olbl.modulate = Color(0.68, 0.72, 0.7)
	olbl.position = Vector3(-HALL_HW + 0.02, y0 + 2.32, (dz0 + dz1) * 0.5)
	olbl.rotation.y = deg_to_rad(90.0)
	add_child(olbl)

	# kepenk: oluklu kapali panjur ("CIKIS KAPALI" — hikaye: vardiya bitmeden cikis yok)
	var shm := StandardMaterial3D.new()
	shm.albedo_color = Color(0.34, 0.35, 0.36)
	shm.metallic = 0.75
	shm.roughness = 0.45
	_detail(shm, 2.5, 0.4)
	for i in 9:
		_box(Vector3(shutter_w, 0.265, 0.05 + (0.012 if i % 2 == 0 else 0.0)),
				Vector3(0, y0 + 0.14 + i * 0.27, HALL_Z1 + 0.03), shm, i == 0)
	var klbl := Label3D.new()
	klbl.text = "ÇIKIŞ — İSTASYON KAPALI"
	klbl.font_size = 52
	klbl.pixel_size = 0.0018
	klbl.modulate = Color(0.75, 0.72, 0.65)
	klbl.position = Vector3(0, y0 + 2.62, HALL_Z1 + 0.08)
	add_child(klbl)
	# kepenk onu kirmizi servis lambasi (donuk, tekinsiz)
	var rl := OmniLight3D.new()
	rl.light_color = Color(1.0, 0.22, 0.15)
	rl.light_energy = 0.5
	rl.omni_range = 3.5
	rl.position = Vector3(0, y0 + 2.9, HALL_Z1 + 0.7)
	add_child(rl)

	# turnike sirasi (z=-16): gercek model (subway_turnstile.glb, dogal olcek);
	# T-3 kabini "anomaly" (tarama gorevi). Her unite kendi kolu ile kilitli.
	var tz := -16.0
	for i in 5:
		var cx := -1.9 + i * 0.95
		_prop("res://assets/models/turnstile/subway_turnstile.glb",
				Vector3(cx, y0, tz), 0.0, 1.34)
		var tb := StaticBody3D.new()
		var tc := CollisionShape3D.new()
		var ts := BoxShape3D.new()
		ts.size = Vector3(0.94, 1.15, 1.42)
		tc.shape = ts
		tc.position = Vector3(cx, y0 + 0.575, tz)
		tb.add_child(tc)
		if i == 2:
			tb.add_to_group("anomaly")   # T-3: terminal taramasinda UYUMSUZ
		add_child(tb)
		var tlbl := Label3D.new()
		tlbl.text = "T-%d" % (i + 1)
		tlbl.font_size = 26
		tlbl.pixel_size = 0.0013
		tlbl.modulate = Color(0.7, 0.74, 0.72)
		tlbl.position = Vector3(cx, y0 + 1.32, tz + 0.72)
		add_child(tlbl)
	# yan bariyerler: gercek CAM panolar + celik dikme/kupeste (metro gise bariyeri).
	# yoksa turnikelerin yanindan yuruyerek gecilirdi
	var glass := StandardMaterial3D.new()
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.albedo_color = Color(0.58, 0.74, 0.72, 0.16)
	glass.roughness = 0.04
	glass.metallic = 0.0
	glass.metallic_specular = 0.9
	glass.cull_mode = BaseMaterial3D.CULL_DISABLED
	for side in [-1.0, 1.0]:
		var bx0 := 2.45                       # turnike sirasinin disi
		var bw := HALL_HW - bx0
		var nposts := int(bw / 1.2)
		var seg := bw / float(nposts)
		for k in nposts:
			var p0: float = side * (bx0 + seg * float(k))
			var pc: float = p0 + side * seg * 0.5
			# cam pano (dikmeler arasi, altta bosluk — gercek bariyer gibi)
			_box(Vector3(seg - 0.09, 0.86, 0.016), Vector3(pc, y0 + 0.56, tz),
					glass, false)
		for k in nposts + 1:
			var px: float = side * bx0 + side * seg * float(k)
			_box(Vector3(0.055, 1.02, 0.055), Vector3(px, y0 + 0.51, tz),
					mat_steel_rail, false)
		var bcx: float = side * (bx0 + bw * 0.5)
		# ust kupeste (paslanmaz boru)
		_tube(Vector3(side * bx0, y0 + 1.05, tz), Vector3(side * HALL_HW, y0 + 1.05, tz),
				0.024, mat_steel_rail)
		# alt celik ray
		_box(Vector3(bw, 0.09, 0.06), Vector3(bcx, y0 + 0.085, tz), mat_steel_rail, false)
		var bb := StaticBody3D.new()
		bb.set_meta("scan_ignore", true)      # gorunmez engel taramaya takilmasin
		var bc := CollisionShape3D.new()
		var bsh := BoxShape3D.new()
		bsh.size = Vector3(bw, 2.2, 0.3)
		bc.shape = bsh
		bc.position = Vector3(bcx, y0 + 1.1, tz)
		bb.add_child(bc)
		add_child(bb)
	# bilet makineleri: dogu duvarina yaslanmis iki unite (bati tarafi ofisin)
	for mz in [-13.0, -14.1]:
		_prop("res://assets/models/ticket_machine/japanese_parking_machine.glb",
				Vector3(HALL_HW - 0.42, y0, mz), -90.0, 1.08)
		var mb := StaticBody3D.new()
		var mc := CollisionShape3D.new()
		var msh := BoxShape3D.new()
		msh.size = Vector3(0.55, 1.15, 0.55)
		mc.shape = msh
		mc.position = Vector3(HALL_HW - 0.42, y0 + 0.575, mz)
		mb.add_child(mc)
		add_child(mb)
	# yangin tupu (dogu duvari dibinde)
	_prop("res://assets/models/korean_fire_extinguisher_01/korean_fire_extinguisher_01.gltf",
			Vector3(HALL_HW - 0.28, y0, -15.3), -90.0, 0.66)

	# fayansli kolonlar (peronla ayni dil): iki cift
	for colp in [Vector3(-4.6, 0, -13.2), Vector3(4.6, 0, -13.2),
			Vector3(-4.6, 0, -19.2), Vector3(4.6, 0, -19.2)]:
		_box(Vector3(0.55, HALL_H, 0.55), Vector3(colp.x, cy, colp.z), mat_marble_tile)
		_box(Vector3(0.575, 0.36, 0.575), Vector3(colp.x, y0 + 0.18, colp.z),
				mat_dark_tile, false)
	# supurgelik: koyu bant tum duvar diplerinde
	_box(Vector3(HALL_HW * 2.0, 0.36, 0.012), Vector3(0, y0 + 0.18, z0 - 0.006),
			mat_dark_tile, false)
	for sside in [-1.0, 1.0]:
		_box(Vector3(HALL_HW - shutter_w * 0.5, 0.36, 0.012),
				Vector3(sside * (shutter_w * 0.5 + (HALL_HW - shutter_w * 0.5) * 0.5),
				y0 + 0.18, HALL_Z1 + 0.006), mat_dark_tile, false)
	_box(Vector3(0.012, 0.36, z0 - HALL_Z1),
			Vector3(HALL_HW - 0.006, y0 + 0.18, (z0 + HALL_Z1) * 0.5), mat_dark_tile, false)
	_box(Vector3(0.012, 0.36, z0 - dz0),
			Vector3(-HALL_HW + 0.006, y0 + 0.18, (z0 + dz0) * 0.5), mat_dark_tile, false)
	_box(Vector3(0.012, 0.36, dz1 - HALL_Z1),
			Vector3(-HALL_HW + 0.006, y0 + 0.18, (dz1 + HALL_Z1) * 0.5), mat_dark_tile, false)
	# tavan borulari: hol boyunca iki hat + dikey inisler
	_tube(Vector3(-6.3, y0 + HALL_H - 0.16, z0), Vector3(-6.3, y0 + HALL_H - 0.16, HALL_Z1),
			0.055, mat_pipe)
	_tube(Vector3(-5.95, y0 + HALL_H - 0.11, z0), Vector3(-5.95, y0 + HALL_H - 0.11, HALL_Z1),
			0.032, mat_pipe)
	for pz in [-13.5, -17.5, -21.0]:
		_tube(Vector3(-6.3, y0 + HALL_H - 0.16, pz), Vector3(-6.3, y0 + HALL_H + 0.05, pz),
				0.02, mat_pipe)
	# aydinlatma: dort saglam, biri titrek, biri olu
	_fixture(Vector3(-4.2, y0 + HALL_H - 0.08, -14.0), 1.3, Color(0.78, 0.9, 1.0),
			0.1, 0.9, Vector3(0, -0.35, 0))
	_fixture(Vector3(4.2, y0 + HALL_H - 0.08, -12.4), 1.25, Color(0.79, 0.9, 1.0),
			0.08, 0.92, Vector3(0, -0.35, 0))
	_fixture(Vector3(0.0, y0 + HALL_H - 0.08, -16.6), 1.4, Color(0.78, 0.9, 1.0),
			0.07, 0.93, Vector3(0, -0.35, 0))
	_fixture(Vector3(4.2, y0 + HALL_H - 0.08, -18.5), 0.7, Color(0.8, 0.88, 1.0),
			0.65, 0.25, Vector3(0, -0.35, 0))
	_fixture(Vector3(-4.2, y0 + HALL_H - 0.08, -20.5), 0.05, Color(0.78, 0.9, 1.0),
			0.7, 0.1, Vector3(0, -0.35, 0))
	_fixture(Vector3(0.0, y0 + HALL_H - 0.08, -20.8), 0.9, Color(0.82, 0.88, 1.0),
			0.3, 0.6, Vector3(0, -0.35, 0))
	# istasyon adi: kepenk ustu bandda buyuk harfler
	var hlbl := Label3D.new()
	hlbl.text = "H İ S A R — 7"
	hlbl.font_size = 88
	hlbl.pixel_size = 0.0024
	hlbl.modulate = Color(0.6, 0.63, 0.62)
	hlbl.position = Vector3(0, y0 + 2.96, HALL_Z1 + 0.09)
	add_child(hlbl)
	# asili yonlendirme: koridor agzinin ustunde "PERON" tabelasi (iki yuzlu)
	var psgn := StandardMaterial3D.new()
	psgn.albedo_color = Color(0.07, 0.11, 0.22)
	psgn.roughness = 0.6
	_box(Vector3(1.7, 0.44, 0.06), Vector3(0, y0 + 2.5, -11.5), psgn, false)
	for rz in [-0.72, 0.72]:
		_tube(Vector3(rz, y0 + 2.72, -11.5), Vector3(rz, y0 + HALL_H, -11.5),
				0.012, mat_metal)
	for pface in [-1.0, 1.0]:
		var plbl := Label3D.new()
		plbl.text = "▼  PERON"
		plbl.font_size = 40
		plbl.pixel_size = 0.0018
		plbl.modulate = Color(0.85, 0.88, 0.9)
		plbl.position = Vector3(0, y0 + 2.5, -11.5 + pface * 0.041)
		if pface < 0.0:
			plbl.rotation.y = PI
		add_child(plbl)
	# duvar posterleri (kepenk yanlari) + uyari tabelalari
	_hall_poster(Vector3(-5.6, y0 + 1.72, HALL_Z1 + 0.03), "HAT PLANI\nKARAHAT", Color(0.5, 0.58, 0.5))
	_hall_poster(Vector3(5.6, y0 + 1.72, HALL_Z1 + 0.03), "SON SEFER\n00:40", Color(0.6, 0.5, 0.42))
	_wall_sign("Sign002", Vector3(-HALL_HW + 0.02, y0 + 1.7, -15.0), 90.0, 0.42)
	_wall_sign("Sign021", Vector3(HALL_HW - 0.02, y0 + 1.6, -19.0), -90.0, 0.46)


## Hol duvar posteri: cerceve + eski kagit + baslik (kuzey duvari, +z yuzu)
func _hall_poster(pos: Vector3, title: String, tint: Color) -> void:
	var frame := StandardMaterial3D.new()
	frame.albedo_color = Color(0.14, 0.15, 0.16)
	frame.metallic = 0.5
	frame.roughness = 0.45
	var paper := StandardMaterial3D.new()
	paper.albedo_color = Color(0.72, 0.7, 0.62)
	paper.roughness = 0.92
	var art := StandardMaterial3D.new()
	art.albedo_color = tint
	art.roughness = 0.9
	_box(Vector3(0.86, 1.18, 0.03), pos, frame, false)
	_box(Vector3(0.78, 1.1, 0.012), pos + Vector3(0, 0, 0.013), paper, false)
	_box(Vector3(0.68, 0.62, 0.008), pos + Vector3(0, 0.14, 0.021), art, false)
	var t := Label3D.new()
	t.text = title
	t.font_size = 22
	t.pixel_size = 0.0012
	t.modulate = Color(0.22, 0.2, 0.18)
	t.position = pos + Vector3(0, -0.33, 0.028)
	add_child(t)


## Teknisyen KONTROL ODASI: oyunun basladigi genis, sicak isikli oda.
## Guvenlik kamerasi masasi (retro bilgisayar → CCTV), alinabilir terminal + fener,
## acik celik kapi, STAFF ONLY. (CLAUDE.md "vadi/guvenli oda".)
func _build_office() -> void:
	var y0 := TOP_Y
	var oh := 2.8                        # oda yuksekligi
	var x0 := -14.0                      # ic bati
	var x1 := -8.8                       # ic dogu (hol duvarinin ic yuzu)
	var zz0 := -11.6                     # ic guney
	var zz1 := -16.6                     # ic kuzey
	var cx := (x0 + x1) * 0.5
	var czm := (zz0 + zz1) * 0.5
	# duvar malzemesi: duz mat siva (eski "sulu/yagli" gorunen boya gitti)
	var mat_owall := StandardMaterial3D.new()
	mat_owall.albedo_color = Color(0.585, 0.575, 0.535)
	mat_owall.roughness = 0.92
	mat_owall.metallic = 0.0
	_detail(mat_owall, 0.9, 0.18)
	# zemin + tavan
	_box(Vector3(x1 - x0 + 0.5, 0.3, zz0 - zz1 + 0.5),
			Vector3(cx, y0 - 0.15, czm), mat_floor_tile)
	_box(Vector3(x1 - x0 + 0.5, 0.3, zz0 - zz1 + 0.5),
			Vector3(cx, y0 + oh + 0.15, czm), mat_stucco, false)
	# duvarlar
	_box(Vector3(0.25, oh, zz0 - zz1 + 0.5),
			Vector3(x0 - 0.125, y0 + oh * 0.5, czm), mat_owall)          # bati
	_box(Vector3(x1 - x0 + 0.5, oh, 0.25),
			Vector3(cx, y0 + oh * 0.5, zz0 + 0.125), mat_owall)          # guney
	_box(Vector3(x1 - x0 + 0.5, oh, 0.25),
			Vector3(cx, y0 + oh * 0.5, zz1 - 0.125), mat_owall)          # kuzey
	# oda tavani (2.8) ile hol yuksekligi farkini kapatan dolgu
	_box(Vector3(x1 - x0 + 0.5, HALL_H - oh + 0.5, zz0 - zz1 + 0.5),
			Vector3(cx, y0 + oh + 0.3 + (HALL_H - oh) * 0.5, czm), mat_void, false)
	# supurgelik
	_box(Vector3(x1 - x0, 0.24, 0.012), Vector3(cx, y0 + 0.12, zz0 - 0.006),
			mat_dark_tile, false)
	_box(Vector3(x1 - x0, 0.24, 0.012), Vector3(cx, y0 + 0.12, zz1 + 0.006),
			mat_dark_tile, false)
	_box(Vector3(0.012, 0.24, zz0 - zz1), Vector3(x0 + 0.006, y0 + 0.12, czm),
			mat_dark_tile, false)

	# --- CCTV masasi (bati duvari): retro bilgisayar + oturma ---
	_prop("res://assets/models/metal_office_desk/metal_office_desk.gltf",
			Vector3(-13.45, y0, -14.5), 90.0, 2.0)
	var db := StaticBody3D.new()
	var dc := CollisionShape3D.new()
	var dsh := BoxShape3D.new()
	dsh.size = Vector3(0.98, 0.82, 2.02)
	dc.shape = dsh
	dc.position = Vector3(-13.45, y0 + 0.41, -14.5)
	db.add_child(dc)
	add_child(db)
	_prop("res://assets/models/retro_computer/retro_computer.glb",
			Vector3(-13.5, y0 + 0.787, -14.5), 90.0, 0.97, true)
	# bilgisayara etkilesim: E → guvenlik kameralari
	var pcb := StaticBody3D.new()
	pcb.add_to_group("interactable")
	pcb.set_meta("prompt", "[E]  GÜVENLİK KAMERALARI")
	pcb.set_meta("on_interact", Callable(self, "_open_cctv"))
	var pcc := CollisionShape3D.new()
	var pcs := BoxShape3D.new()
	pcs.size = Vector3(0.9, 0.75, 1.0)
	pcc.shape = pcs
	pcc.position = Vector3(-13.45, y0 + 1.2, -14.5)
	pcb.add_child(pcc)
	add_child(pcb)
	# masa basinda koltuk (yuzu masaya donuk)
	_prop("res://assets/models/GreenChair_01/GreenChair_01.gltf",
			Vector3(-12.55, y0, -14.5), 90.0, 1.06)

	# --- zimmet masasi (guney duvari): el terminali + fener buradan alinir ---
	_prop("res://assets/models/metal_office_desk/metal_office_desk.gltf",
			Vector3(-11.3, y0, -12.15), 180.0, 2.0)
	var db2 := StaticBody3D.new()
	var dc2 := CollisionShape3D.new()
	var dsh2 := BoxShape3D.new()
	dsh2.size = Vector3(2.02, 0.82, 0.98)
	dc2.shape = dsh2
	dc2.position = Vector3(-11.3, y0 + 0.41, -12.15)
	db2.add_child(dc2)
	add_child(db2)
	# alinabilir: EL TERMINALI (masada duruyor; E ile alinir → TAB aktiflesir)
	var tprop := _prop("res://assets/models/terminal_device/terminal_device.glb",
			Vector3(-11.05, y0 + 0.787, -12.2), 38.0, 0.4, true)
	var tpick := StaticBody3D.new()
	tpick.add_to_group("interactable")
	tpick.set_meta("prompt", "[E]  TERMİNALİ AL")
	tpick.set_meta("on_interact", Callable(self, "_pickup_terminal"))
	var tpc := CollisionShape3D.new()
	var tps := BoxShape3D.new()
	tps.size = Vector3(0.45, 0.4, 0.45)
	tpc.shape = tps
	tpc.position = Vector3(-11.05, y0 + 0.95, -12.2)
	tpick.add_child(tpc)
	add_child(tpick)
	_pickup_nodes["terminal"] = [tprop, tpick]
	# alinabilir: EL FENERI (E ile alinir → F aktiflesir)
	var fprop := _prop("res://assets/models/vintage_flashlight/vintage_flashlight.gltf",
			Vector3(-11.75, y0 + 0.787, -12.2), -35.0, 0.305, true)
	var fpick := StaticBody3D.new()
	fpick.add_to_group("interactable")
	fpick.set_meta("prompt", "[E]  FENERİ AL")
	fpick.set_meta("on_interact", Callable(self, "_pickup_flashlight"))
	var fpc := CollisionShape3D.new()
	var fps := BoxShape3D.new()
	fps.size = Vector3(0.4, 0.35, 0.4)
	fpc.shape = fps
	fpc.position = Vector3(-11.75, y0 + 0.92, -12.2)
	fpick.add_child(fpc)
	add_child(fpick)
	_pickup_nodes["fener"] = [fprop, fpick]
	# masa ustu duzeni: telsiz cihazi solda, kol lambasi arkada masaya donuk
	_prop("res://assets/models/vintage_radio_transceiver/vintage_radio_transceiver.gltf",
			Vector3(-10.45, y0 + 0.787, -12.25), 205.0, 0.62, true)
	_prop("res://assets/models/desk_lamp_arm_01/desk_lamp_arm_01.gltf",
			Vector3(-12.05, y0 + 0.787, -11.95), 185.0, 0.89, true)
	_prop("res://assets/models/office_notepads/office_notepads.gltf",
			Vector3(-10.95, y0 + 0.787, -12.5), 96.0, 0.5, true)
	_prop("res://assets/models/clipboard/clipboard.gltf",
			Vector3(-11.5, y0 + 0.787, -12.55), 14.0, 0.34, true)
	# masa lambasi isigi: masanin USTUNE duser (acisi duzeltildi)
	var dl := OmniLight3D.new()
	dl.light_color = Color(1.0, 0.76, 0.46)
	dl.light_energy = 0.9
	dl.omni_range = 2.4
	dl.shadow_enabled = true
	dl.position = Vector3(-11.6, y0 + 1.25, -12.35)
	add_child(dl)

	# --- kuzey duvari: kitaplik + cekmeceli dolap (ferah yerlesim) ---
	_prop("res://assets/models/wooden_bookshelf_worn/wooden_bookshelf_worn.gltf",
			Vector3(-13.1, y0, -16.32), 0.0, 2.06)
	var bb2 := StaticBody3D.new()
	var bc2 := CollisionShape3D.new()
	var bs2 := BoxShape3D.new()
	bs2.size = Vector3(1.4, 2.08, 0.62)
	bc2.shape = bs2
	bc2.position = Vector3(-13.1, y0 + 1.03, -16.32)
	bb2.add_child(bc2)
	add_child(bb2)
	_prop("res://assets/models/drawer_cabinet/drawer_cabinet.gltf",
			Vector3(-11.35, y0, -16.35), 0.0, 1.88)
	var cb := StaticBody3D.new()
	var cc := CollisionShape3D.new()
	var csh := BoxShape3D.new()
	csh.size = Vector3(1.16, 1.9, 0.52)
	cc.shape = csh
	cc.position = Vector3(-11.35, y0 + 0.95, -16.35)
	cb.add_child(cc)
	add_child(cb)
	_prop("res://assets/models/vintage_electric_kettle/vintage_electric_kettle.gltf",
			Vector3(-11.35, y0 + 1.885, -16.32), 70.0, 0.32, true)
	# kose: plastik yedek sandalye + koliler + yangin tupu
	_prop("res://assets/models/plastic_monobloc_chair_01/plastic_monobloc_chair_01.gltf",
			Vector3(-9.45, y0, -16.05), 205.0, 0.88)
	_prop("res://assets/models/cardboard_box_01/cardboard_box_01.gltf",
			Vector3(-9.3, y0, -15.25), 25.0, 0.62)
	_prop("res://assets/models/cardboard_box_01/cardboard_box_01.gltf",
			Vector3(-9.35, y0 + 0.42, -15.28), 70.0, 0.5)
	_prop("res://assets/models/korean_fire_extinguisher_01/korean_fire_extinguisher_01.gltf",
			Vector3(-9.05, y0, -12.1), 135.0, 0.66)

	# --- duvar saati (bati duvari, CCTV masasinin ustu): 03:47'de durmus ---
	var oclk := _prop("res://assets/models/clock/basic_clock_rigged.glb",
			Vector3(-13.93, y0 + 2.15, -13.4), 0.0, 0.32, false)
	if oclk:
		_set_clock_time(oclk, 3, 47)

	# --- mantar pano (guney duvari, zimmet masasinin ustu) + notlar ---
	var cork := StandardMaterial3D.new()
	cork.albedo_color = Color(0.42, 0.3, 0.19)
	cork.roughness = 0.95
	_detail(cork, 4.0, 0.5)
	_box(Vector3(1.5, 0.9, 0.03), Vector3(-11.3, y0 + 1.78, zz0 - 0.015), cork, false)
	var rng := RandomNumberGenerator.new()
	rng.seed = 12
	for i in 6:
		var pap := StandardMaterial3D.new()
		pap.albedo_color = Color(0.82, 0.8, 0.72) if i % 3 != 0 else Color(0.83, 0.78, 0.55)
		pap.roughness = 0.9
		var px2 := -11.95 + rng.randf_range(0.0, 1.3)
		var py2 := y0 + 1.5 + rng.randf_range(0.0, 0.5)
		var pq := _box(Vector3(rng.randf_range(0.13, 0.2), rng.randf_range(0.16, 0.24), 0.012),
				Vector3(px2, py2, zz0 - 0.038), pap, false)
		pq.rotation.z = rng.randf_range(-0.08, 0.08)
	var note := Label3D.new()
	note.text = "VARDİYA: 23:00–06:00\ntek kişi"
	note.font_size = 13
	note.pixel_size = 0.001
	note.modulate = Color(0.25, 0.22, 0.2)
	note.position = Vector3(-11.6, y0 + 1.9, zz0 - 0.047)
	note.rotation.y = PI
	add_child(note)
	var note2 := Label3D.new()
	note2.text = "A panosu ARIZALI\ndokunma — C."
	note2.font_size = 12
	note2.pixel_size = 0.001
	note2.modulate = Color(0.3, 0.16, 0.14)
	note2.position = Vector3(-10.95, y0 + 1.58, zz0 - 0.047)
	note2.rotation.y = PI
	note2.rotation.z = deg_to_rad(4.0)
	add_child(note2)

	# --- kapi: hole acilan celik kapi, ACIK durur (ic duvara yasli) ---
	var doorm := StandardMaterial3D.new()
	doorm.albedo_color = Color(0.34, 0.37, 0.39)
	doorm.metallic = 0.45
	doorm.roughness = 0.42
	_detail(doorm, 1.2, 0.12)
	var leaf := _box(Vector3(0.055, 2.06, 1.04), Vector3(-8.87, y0 + 1.03, -14.16),
			doorm, true)
	# kol
	_box(Vector3(0.03, 0.03, 0.16), Vector3(-8.905, y0 + 1.05, -13.75), mat_steel_rail, false)
	leaf.rotation.y = deg_to_rad(-4.0)
	# STAFF ONLY plakasi (hol tarafi, kapinin yani)
	var plate := StandardMaterial3D.new()
	plate.albedo_color = Color(0.85, 0.83, 0.78)
	plate.roughness = 0.5
	_box(Vector3(0.015, 0.2, 0.5), Vector3(-8.494, y0 + 1.92, -12.05), plate, false)
	var so := Label3D.new()
	so.text = "STAFF ONLY"
	so.font_size = 30
	so.pixel_size = 0.0011
	so.modulate = Color(0.72, 0.12, 0.1)
	so.position = Vector3(-8.483, y0 + 1.95, -12.05)
	so.rotation.y = deg_to_rad(90.0)
	add_child(so)
	var so2 := Label3D.new()
	so2.text = "PERSONEL HARİCİ GİRİLMEZ"
	so2.font_size = 13
	so2.pixel_size = 0.001
	so2.modulate = Color(0.25, 0.24, 0.22)
	so2.position = Vector3(-8.483, y0 + 1.87, -12.05)
	so2.rotation.y = deg_to_rad(90.0)
	add_child(so2)

	# --- aydinlatma: iki sicak armatur (vadi — nefes alani) ---
	_fixture(Vector3(-11.0, y0 + oh - 0.08, -13.6), 1.5, Color(1.0, 0.88, 0.66),
			0.05, 0.96, Vector3(0, -0.3, 0))
	_fixture(Vector3(-13.2, y0 + oh - 0.08, -15.3), 0.7, Color(1.0, 0.85, 0.6),
			0.25, 0.7, Vector3(0, -0.3, 0))


var _pickup_nodes := {}          # "terminal"/"fener" -> [prop, etkilesim govdesi]


## Zimmet masasindan terminali al: TAB aktiflesir
func _pickup_terminal() -> void:
	if not _pickup_nodes.has("terminal"):
		return
	for n in _pickup_nodes["terminal"]:
		if is_instance_valid(n):
			(n as Node).queue_free()
	_pickup_nodes.erase("terminal")
	var term := get_tree().get_first_node_in_group("terminal")
	if term:
		term.set("acquired", true)
	var r := get_tree().get_first_node_in_group("radio")
	if r:
		r.call("say", "MERKEZ", "Terminal sende mi? TAB ile aç. Batarya zimmetli, idareli kullan.", 5.5)


## Zimmet masasindan feneri al: F aktiflesir
func _pickup_flashlight() -> void:
	if not _pickup_nodes.has("fener"):
		return
	for n in _pickup_nodes["fener"]:
		if is_instance_valid(n):
			(n as Node).queue_free()
	_pickup_nodes.erase("fener")
	var p := get_tree().get_first_node_in_group("player")
	if p:
		p.set("has_flashlight", true)


func _open_cctv() -> void:
	var c := get_tree().get_first_node_in_group("cctv")
	if c:
		c.call("open")


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


## ambientCG CC0 uyari tabelasi: alfa-kesmeli PBR plaka, duvara monte.
## Doku setleri assets/models/signs/<id>/ altinda (Color+Opacity birlesik PNG).
func _wall_sign(id: String, pos: Vector3, yaw_deg: float, size := 0.42) -> void:
	var base := "res://assets/models/signs/%s/%s" % [id, id]
	var m := StandardMaterial3D.new()
	m.albedo_texture = load(base + "_color_a.png")
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	m.alpha_scissor_threshold = 0.5
	m.normal_enabled = true
	m.normal_texture = load(base + "_normal.jpg")
	m.roughness_texture = load(base + "_rough.jpg")
	m.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_GRAYSCALE
	# boyali levha mat okusun; metallic + yakin lamba speculari yuzeyi patlatiyor
	m.metallic = 0.0
	m.roughness = 1.0
	m.metallic_specular = 0.0
	var q := QuadMesh.new()
	q.size = Vector2(size, size)
	var mi := MeshInstance3D.new()
	mi.mesh = q
	mi.material_override = m
	mi.position = pos
	mi.rotation.y = deg_to_rad(yaw_deg)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)


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


## Rigli saatin ibrelerini verilen saate kilitle (kemik pozu; saat calismiyor)
func _set_clock_time(clk: Node3D, hour: int, minute: int) -> void:
	var sk := clk.find_child("Skeleton3D", true, false) as Skeleton3D
	if sk == null:
		return
	var setups := [
		["hour_hand_04", (float(hour % 12) + minute / 60.0) / 12.0],
		["minute_hand_02", minute / 60.0],
		["second_hand_03", 0.62],
	]
	for s in setups:
		var bi := sk.find_bone(s[0])
		if bi >= 0:
			var rest := sk.get_bone_rest(bi).basis.get_rotation_quaternion()
			sk.set_bone_pose_rotation(bi,
					rest * Quaternion(Vector3(0, 0, 1), -TAU * float(s[1])))


func _build_props() -> void:
	# --- CIKIS tabelasi: gercek isikli tabela modeli (kullanicinin way_out.glb'si) ---
	# yaw 180: isikli on yuz perona baksin
	_prop("res://assets/models/way_out/way_out.glb",
			Vector3(0, 2.76, 0.7), 180.0, 0.95, false)
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
		_aux_lights.append(cw)

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

	# --- PANO A salteri: oyunun ilk gorevi (E ile etkilesim) ---
	_switch_lever = MeshInstance3D.new()
	var lvm := BoxMesh.new()
	lvm.size = Vector3(0.028, 0.085, 0.03)
	_switch_lever.mesh = lvm
	var lever_m := StandardMaterial3D.new()
	lever_m.albedo_color = Color(0.72, 0.18, 0.13)
	lever_m.metallic = 0.4
	lever_m.roughness = 0.5
	_switch_lever.material_override = lever_m
	_switch_lever.position = Vector3(-4.28, 1.5, 0.128)
	_switch_lever.rotation.x = deg_to_rad(35.0)   # asagi = kapali
	add_child(_switch_lever)
	var swb := StaticBody3D.new()
	swb.add_to_group("interactable")
	swb.set_meta("prompt", "[E]  ŞALTERİ KALDIR")
	swb.set_meta("on_interact", Callable(self, "_on_panel_switch"))
	var swc := CollisionShape3D.new()
	var sws := BoxShape3D.new()
	sws.size = Vector3(0.22, 0.3, 0.18)
	swc.shape = sws
	swc.position = Vector3(-4.28, 1.5, 0.13)
	swb.add_child(swc)
	add_child(swb)

	# --- bozuk saat: gercek rigli model, 04:17'de donmus (merdiven agzinin sag ustu) ---
	# yaw -90: kadran perona baksin (90'da sirti donuktu — "saat ters" geri bildirimi)
	var clk := _prop("res://assets/models/clock/basic_clock_rigged.glb",
			Vector3(4.1, 2.5, 0.07), -90.0, 0.35, false)
	if clk:
		_set_clock_time(clk, 4, 17)

	# --- posterler: cerceve + kagit + gorsel alan + baslik (onden okunur afisler) ---
	var pcolors := [Color(0.32, 0.38, 0.4), Color(0.42, 0.31, 0.24), Color(0.45, 0.45, 0.4),
			Color(0.25, 0.3, 0.36)]
	var ptitles := ["SEFER SAATLERİ", "GÜVENLİK HERKESİN\nİŞİDİR", "HİSAR-7\n50. YIL", "KAYIP EŞYA\nDANIŞMA"]
	var pxs := [-11.6, -5.7, 5.6, 12.1]
	for i in 4:
		var frame := StandardMaterial3D.new()
		frame.albedo_color = Color(0.55, 0.57, 0.58)
		frame.metallic = 0.6
		frame.roughness = 0.4
		_detail(frame, 3.0, 0.25)
		_box(Vector3(0.66, 0.94, 0.022), Vector3(pxs[i], 1.62, 0.011), frame, false)
		# eskimis afis kagidi
		var paper := StandardMaterial3D.new()
		paper.albedo_color = Color(0.68, 0.66, 0.60)
		paper.roughness = 0.85
		_detail(paper, 2.0, 0.3, true)
		_box(Vector3(0.6, 0.88, 0.02), Vector3(pxs[i], 1.62, 0.018), paper, false)
		# gorsel alani (ust yarim)
		var pm := StandardMaterial3D.new()
		pm.albedo_color = pcolors[i]
		pm.roughness = 0.6
		_detail(pm, 2.0, 0.35, true)
		_box(Vector3(0.52, 0.5, 0.016), Vector3(pxs[i], 1.79, 0.024), pm, false)
		# baslik (alt bant)
		var plabel := Label3D.new()
		plabel.text = ptitles[i]
		plabel.font_size = 30
		plabel.pixel_size = 0.0012
		plabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		plabel.modulate = Color(0.18, 0.20, 0.22)
		plabel.position = Vector3(pxs[i], 1.40, 0.032)
		add_child(plabel)

	# --- peron kenari uyari yazisi (karsi duvarda kucuk) ---
	var wlbl := Label3D.new()
	wlbl.text = "SARI ÇİZGİYİ GEÇMEYİNİZ"
	wlbl.font_size = 40
	wlbl.pixel_size = 0.0016
	wlbl.modulate = Color(0.75, 0.78, 0.8, 0.85)
	wlbl.position = Vector3(0, 0.35, PIT_Z1 - 0.09)
	wlbl.rotation.y = PI
	add_child(wlbl)

	# --- uyari tabelalari: ambientCG CC0 PBR doku setleri (paslanmis plakalar) ---
	# yuksek gerilim: ana pano (box-01) kapaginin sol ust kosesinde
	_wall_sign("Sign009", Vector3(-4.62, 1.58, 0.118), 0.0, 0.3)
	# kaygan zemin: merdiven agzinin sagindaki duvarda (islak zemin temasi)
	_wall_sign("Sign005", Vector3(3.55, 1.55, 0.03), 0.0, 0.38)
	# genel tehlike: peron uclarinda, tunel agizlarina yakin
	_wall_sign("Sign002", Vector3(-14.3, 1.7, 0.03), 0.0, 0.42)
	_wall_sign("Sign002", Vector3(14.3, 1.7, 0.03), 0.0, 0.42)
	# paslanmis kirmizi uyari: karsi duvarda, tunel agzina dogru (yasak bolge hissi)
	_wall_sign("Sign021", Vector3(12.6, 1.5, PIT_Z1 - 0.03), 180.0, 0.5)

	# --- ankesorlu telefon: sol duvarda, poster ile bakim kosesi arasinda ---
	_prop("res://assets/models/payphone/korean_payphone.glb",
			Vector3(-12.55, 1.35, 0.16), 0.0, 0.74, false)

	# --- otomat: poster ile bank arasinda, sirti duvara sifir ---
	# modelin AABB derinligi genis (1.29 m); %72 z-sikistirma ile gercekci
	# makine derinligine (~0.93 m) getirilir ve duvara yaslanir
	var vend := _prop("res://assets/models/vending_machine/vending_machine.glb",
			Vector3(6.8, 0.0, 0.475), 0.0, 1.83)
	if vend:
		vend.scale.z = 0.72
	var vsb := StaticBody3D.new()
	var vcs := CollisionShape3D.new()
	var vbs := BoxShape3D.new()
	vbs.size = Vector3(1.1, 1.9, 0.95)
	vcs.shape = vbs
	vcs.position = Vector3(6.8, 0.95, 0.48)
	vsb.add_child(vcs)
	add_child(vsb)
	# otomatin ic aydinlatmasi: soguk, kisik makine isigi (on camdan sizar)
	var vl := OmniLight3D.new()
	vl.light_color = Color(0.75, 0.85, 1.0)
	vl.light_energy = 0.55
	vl.omni_range = 2.2
	vl.position = Vector3(6.8, 1.2, 1.3)
	add_child(vl)


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
		rot := Vector3.ZERO, use_model := true) -> OmniLight3D:
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
	return light


func _build_lights() -> void:
	# merdiven: duzluk uzerinde ana tup (soguk, baskin)
	_fixture(Vector3(0, 4.28, -3.2), 2.8, Color(0.76, 0.90, 1.0),
			0.10, 0.82, Vector3(0, -0.35, 0))
	# ust kol armaturu — bozuk, cogunlukla sonuk, karanligin esiginde
	_fixture(Vector3(0, 5.68, -6.6), 0.5, Color(0.8, 0.9, 1.0),
			0.5, 0.3, Vector3(0, -0.3, 0))
	# peron isik sirasi: kimi saglam, biri titrek, biri olu (CLAUDE.md atmosferi)
	# siralanmis referanslari sakla — blackout olayi ucdan uca soker
	var xs := [-13.0, -8.66, -4.33, 0.0, 4.33, 8.66, 13.0]
	var energies := [0.9, 1.4, 1.5, 1.6, 0.1, 1.5, 0.9]
	var flickers := [0.12, 0.55, 0.08, 0.06, 0.6, 0.08, 0.15]
	var drops := [0.8, 0.3, 0.9, 0.92, 0.15, 0.9, 0.75]
	for i in xs.size():
		var lt := _fixture(Vector3(xs[i], CEIL_Y - 0.08, 3.6), energies[i],
				Color(0.78, 0.9, 1.0), flickers[i], drops[i], Vector3(0, -0.35, 0))
		_plat_lights.append(lt)
	# tunel agizlarina sizan cok soluk isik (derinlik hissi)
	for sx in [-1.0, 1.0]:
		var t := OmniLight3D.new()
		t.light_color = Color(0.55, 0.7, 0.85)
		t.light_energy = 0.35
		t.omni_range = 7.0
		t.position = Vector3(sx * (PLAT_L - 2.5), 1.2, (PIT_Z0 + PIT_Z1) * 0.5)
		add_child(t)
		_aux_lights.append(t)
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
		_aux_lights.append(d)


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
		# gerilim muzigi kendi bus'ina gider; spektrum analizoru seviyesini olcer
		# ve ekran kenari kararmasini (tension_dark) surer — bkz. _process
		var bus_idx := AudioServer.bus_count
		AudioServer.add_bus(bus_idx)
		AudioServer.set_bus_name(bus_idx, "Tension")
		AudioServer.set_bus_send(bus_idx, "Master")
		AudioServer.add_bus_effect(bus_idx, AudioEffectSpectrumAnalyzer.new())
		_tension_inst = AudioServer.get_bus_effect_instance(bus_idx, 0)
		var mus := AudioStreamPlayer.new()
		mus.stream = stream
		mus.volume_db = -12.0
		mus.autoplay = true
		mus.bus = "Tension"
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

	# uzak hayalet tren: gercek kayit varsa onu kullan (kullanicinin Train.mp3'u),
	# yoksa arka planda sentezle
	var real_train: AudioStream = load("res://assets/audio/train_real.mp3")
	if real_train != null:
		_train_ready(real_train)
	else:
		WorkerThreadPool.add_task(func() -> void:
			var w := _make_train()
			call_deferred("_train_ready", w))

	# fisiltilar: oyuncunun yakininda, arkasindan gelen kisa rastgele dilimler
	# fisiltilar baslangicta YOK — anons olayindan sonra baslar (_anons_event)
	_whisper_stream = load("res://assets/audio/whispers.mp3")

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
	_post_mat = pm
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

	# etkilesim ipucu: ekran ortasinin hemen alti ("[E] ..." — player.gd yonetir)
	var ilbl := Label.new()
	ilbl.add_to_group("interact_label")
	ilbl.visible = false
	ilbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	ilbl.offset_top = 90.0
	ilbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ilbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ilbl.add_theme_font_size_override("font_size", 19)
	ilbl.add_theme_color_override("font_color", Color(0.88, 0.94, 0.9, 0.92))
	ilbl.add_theme_color_override("font_outline_color", Color(0, 0.02, 0.02, 0.85))
	ilbl.add_theme_constant_override("outline_size", 6)
	layer.add_child(ilbl)


func _build_pause_menu() -> void:
	var pm := CanvasLayer.new()
	pm.set_script(load("res://scripts/pause_menu.gd"))
	add_child(pm)


func _spawn_player() -> void:
	var p := CharacterBody3D.new()
	p.set_script(load("res://scripts/player.gd"))
	# oyun kontrol odasinda baslar (zimmet masasina donuk — terminal + fener orada)
	p.position = Vector3(-10.3, TOP_Y + 0.02, -14.6)
	p.add_to_group("player")
	add_child(p)
	p.call("set_view", 154.0, 2.0)
	# siluet korkutmacasi: peron ucunda arkani donunce merdivene kacan figur.
	# Baslangicta KAPALI — telefon olayindan sonra aktiflesir (gec asama korkusu)
	_scare = Node3D.new()
	_scare.set_script(load("res://scripts/scare_figure.gd"))
	# nefes kabarmasi (kullanicinin sesi): figur belirince nefes yukselir,
	# figur kaybolduktan sonra da bir sure duyulmaya devam eder
	_scare.set("sting", load("res://assets/audio/breath_swell.mp3"))
	add_child(_scare)


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
