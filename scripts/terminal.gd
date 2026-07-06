extends Node3D
## El terminali (CLAUDE.md §4.1) — diegetic HUD. Kameranin cocugu olarak yasar.
## TAB: kaldir/indir. Kalkikken 1-4: sekme (OKUMA/TARAMA/GOREV/HAT), sol tik: tarama.
## Ekran bir SubViewport'ta cizilir, cihaz mesh'ine emissive doku olarak yansir.
## Govde prosedurel placeholder — gercek model gelince sadece _build_device degisir.

const SCREEN_W := 640
const SCREEN_H := 343
const GREEN := Color(0.45, 1.0, 0.62)
const GREEN_DIM := Color(0.30, 0.62, 0.42)
const AMBER := Color(1.0, 0.72, 0.25)
const BG := Color(0.015, 0.045, 0.03)

const POS_DOWN := Vector3(0.30, -0.80, -0.50)
const ROT_DOWN := Vector3(-1.35, 0.25, 0.1)
const POS_UP := Vector3(0.175, -0.155, -0.40)
const ROT_UP := Vector3(-0.20, 0.06, 0.02)

var is_up := false
var acquired := false         # zimmet masasindan alinana kadar TAB calismaz
var battery := 100.0
var awareness := 0.0          # yerel sayac (AwarenessManager gelene kadar)
var _tab := 0                 # 0 okuma, 1 tarama, 2 gorev, 3 hat
var _t := 0.0
var _scan_busy := false
var _idle_noise := FastNoiseLite.new()
var _lag := Vector2.ZERO      # kamera donusune gecikmeli takip (sway)
var _prev_pbasis := Basis.IDENTITY

var _vp: SubViewport
var _mono: SystemFont
var _tab_btns: Array[Label] = []
var _pages: Array[Control] = []
var _batt_lbl: Label
var _clock_lbl: Label
var _read_lbls := {}          # isim -> deger Label
var _scan_status: Label
var _scan_result: Label
var _sig_bar: Label
var _sig_info: Label
var _aw_fill: ColorRect
var _log_page: Control
var _log_lines: Array[String] = []


func _ready() -> void:
	add_to_group("terminal")
	_mono = SystemFont.new()
	_mono.font_names = ["Consolas", "Courier New"]
	_idle_noise.seed = 31
	_idle_noise.frequency = 1.0
	if get_parent() is Node3D:
		_prev_pbasis = (get_parent() as Node3D).global_transform.basis
	_build_screen_ui()
	_build_device()
	position = POS_DOWN
	rotation = ROT_DOWN
	set_process(true)


# ------------------------------------------------------------------ cihaz govdesi

# el pozu (calisma zamaninda ayarlanabilir — _apply_hand_pose)
# NOT: hand.glb SOL eldir; hand_mirror=true ile aynalanip sag el olarak kullanilir
var hand_pos := Vector3(0.045, -0.06, 0.035)
var hand_rot := Vector3(-65.0, 45.0, -125.0)   # derece
var hand_scale := 0.12
var hand_mirror := true


func _build_device() -> void:
	# gercek cihaz modeli (kullanicinin handheld_terminal-thingy.glb'si)
	# on yuz +Z — kameraya donuk. Ust paneline kendi ekranimiz bindirilir.
	var holder := Node3D.new()
	holder.name = "Device"
	add_child(holder)
	var ps: PackedScene = load("res://assets/models/terminal_device/terminal_device.glb")
	var dev: Node3D = ps.instantiate()
	holder.add_child(dev)
	holder.scale = Vector3.ONE * 0.85  # ekranda cok yer kaplamasin
	# on yuz kameraya donuk olsun (sagda durdugu icin hafif sola cevrilir)
	holder.rotation_degrees.y = -13.0

	# ekran kaplamasi: cihazin ust ekran bolgesine oturan emissive quad
	var scr := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(0.114, 0.061)
	scr.mesh = qm
	var sm := StandardMaterial3D.new()
	var vt := _vp.get_texture()
	sm.albedo_color = Color.BLACK
	sm.emission_enabled = true
	sm.emission_texture = vt
	sm.emission_energy_multiplier = 1.4
	sm.roughness = 1.0
	sm.metallic_specular = 0.0
	scr.material_override = sm
	scr.position = Vector3(-0.011, 0.082, 0.0445)
	holder.add_child(scr)

	# rigli el: cihazin sag tutma rayini kavrar
	var hps: PackedScene = load("res://assets/models/hand/hand_rigged.glb")
	if hps:
		var hh := Node3D.new()
		hh.name = "HandHolder"
		add_child(hh)
		var hand: Node3D = hps.instantiate()
		hh.add_child(hand)
		_apply_hand_pose()

	# ekran isigi ele/yuze vursun (cok kisik, notr — model kendi renginde kalsin)
	var gl := OmniLight3D.new()
	gl.light_color = Color(0.95, 0.97, 0.95)
	gl.light_energy = 0.0
	gl.omni_range = 0.65
	gl.position = Vector3(0, 0.05, 0.1)
	gl.name = "ScreenGlow"
	add_child(gl)

	# viewmodel golgesi yere dusmesin
	_disable_shadows(self)


func _disable_shadows(node: Node) -> void:
	if node is GeometryInstance3D:
		(node as GeometryInstance3D).cast_shadow = \
				GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for ch in node.get_children():
		_disable_shadows(ch)


func _apply_hand_pose() -> void:
	var hh := get_node_or_null("HandHolder") as Node3D
	if hh:
		hh.position = hand_pos
		hh.rotation_degrees = hand_rot
		hh.scale = Vector3(-hand_scale if hand_mirror else hand_scale,
				hand_scale, hand_scale)


## Parmak kavramasini sikilastir/gevset (rig: forearm→palm→fingers zinciri)
func set_finger_curl(deg: float) -> void:
	var hh := get_node_or_null("HandHolder")
	if hh == null:
		return
	var sk := hh.find_child("Skeleton3D", true, false) as Skeleton3D
	if sk == null:
		return
	var bi := sk.find_bone("fingers")
	if bi >= 0:
		sk.set_bone_pose_rotation(bi,
				Quaternion(Vector3.RIGHT, deg_to_rad(deg)) * sk.get_bone_rest(bi).basis.get_rotation_quaternion())


# ------------------------------------------------------------------ ekran arayuzu

func _lbl(parent: Control, text: String, pos: Vector2, size: int,
		col := GREEN) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.add_theme_font_override("font", _mono)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	parent.add_child(l)
	return l


func _build_screen_ui() -> void:
	_vp = SubViewport.new()
	_vp.size = Vector2i(SCREEN_W, SCREEN_H)
	_vp.disable_3d = true
	_vp.transparent_bg = false
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_vp)

	var root := Control.new()
	root.size = Vector2(SCREEN_W, SCREEN_H)
	_vp.add_child(root)

	var bg := ColorRect.new()
	bg.size = root.size
	bg.color = BG
	root.add_child(bg)

	# ust bar
	_lbl(root, "HİSAR-7 // BAKIM TERMİNALİ v2.3", Vector2(14, 8), 15, GREEN_DIM)
	_batt_lbl = _lbl(root, "", Vector2(SCREEN_W - 92, 8), 15)
	_clock_lbl = _lbl(root, "", Vector2(SCREEN_W - 92, 26), 15, GREEN_DIM)
	var hr := ColorRect.new()
	hr.position = Vector2(10, 30)
	hr.size = Vector2(SCREEN_W - 110, 1)
	hr.color = GREEN_DIM
	root.add_child(hr)

	# sekme baslıklari
	var names := ["[1]OKUMA", "[2]TARAMA", "[3]GÖREV", "[4]HAT"]
	for i in 4:
		var tb := _lbl(root, names[i], Vector2(14 + i * 156, 40), 16)
		_tab_btns.append(tb)

	# sayfalar
	for i in 4:
		var page := Control.new()
		page.position = Vector2(0, 72)
		page.size = Vector2(SCREEN_W, SCREEN_H - 72)
		root.add_child(page)
		_pages.append(page)

	_build_page_readings(_pages[0])
	_build_page_scan(_pages[1])
	_build_page_log(_pages[2])
	_build_page_signal(_pages[3])

	# dikkat cubugu (ince, alt kenar) — CLAUDE §4.3
	_lbl(root, "HAT GÜRÜLTÜSÜ", Vector2(14, SCREEN_H - 24), 11, GREEN_DIM)
	var aw_bg := ColorRect.new()
	aw_bg.position = Vector2(130, SCREEN_H - 19)
	aw_bg.size = Vector2(SCREEN_W - 150, 6)
	aw_bg.color = Color(0.06, 0.14, 0.09)
	root.add_child(aw_bg)
	_aw_fill = ColorRect.new()
	_aw_fill.position = aw_bg.position
	_aw_fill.size = Vector2(0, 6)
	_aw_fill.color = GREEN
	root.add_child(_aw_fill)

	# CRT tarama cizgileri
	var scan := ColorRect.new()
	scan.size = root.size
	scan.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shm := ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = """
shader_type canvas_item;
void fragment() {
	float ln = sin(UV.y * 170.0 * 3.14159) * 0.5 + 0.5;
	float vig = smoothstep(1.05, 0.55, length(UV - 0.5) * 1.35);
	COLOR = vec4(vec3(0.0), (0.22 * ln + 0.10) * vig + (1.0 - vig) * 0.55);
}
"""
	shm.shader = sh
	scan.material = shm
	root.add_child(scan)
	_set_tab(0)


func _build_page_readings(p: Control) -> void:
	var rows := [["BASINÇ", "hPa"], ["SICAKLIK", "°C"], ["HAT GÜRÜLTÜSÜ", "dB"]]
	for i in rows.size():
		_lbl(p, rows[i][0], Vector2(18, 14 + i * 52), 18, GREEN_DIM)
		var v := _lbl(p, "—", Vector2(310, 8 + i * 52), 30)
		_lbl(p, rows[i][1], Vector2(520, 14 + i * 52), 16, GREEN_DIM)
		_read_lbls[rows[i][0]] = v
	_lbl(p, "ref: 1013.0 / 14.0 / <-46", Vector2(18, 178), 12, GREEN_DIM)


func _build_page_scan(p: Control) -> void:
	_lbl(p, "HEDEFE TUT — SOL TIK: TARA", Vector2(18, 12), 16, GREEN_DIM)
	_scan_status = _lbl(p, "HAZIR", Vector2(18, 52), 26)
	_scan_result = _lbl(p, "", Vector2(18, 100), 30)
	_lbl(p, "her tarama: batarya -%4", Vector2(18, 178), 12, GREEN_DIM)


func _build_page_log(p: Control) -> void:
	_log_page = p
	_log_lines = [
		"23:41  vardiya kaydı açıldı",
		"23:42  MERKEZ bağlantısı: OK",
		"       (arşiv: 2 eski kayıt — kilitli)",
	]
	_refresh_log()


## Gorev/log satiri ekle (radio ve gorev sistemi cagirir)
func add_log(text: String) -> void:
	_log_lines.append(text)
	while _log_lines.size() > 7:
		_log_lines.remove_at(0)
	_refresh_log()


func _refresh_log() -> void:
	if _log_page == null:
		return
	for ch in _log_page.get_children():
		ch.queue_free()
	for i in _log_lines.size():
		var col := GREEN if _log_lines[i].begins_with("GÖREV") else GREEN_DIM
		_lbl(_log_page, _log_lines[i], Vector2(18, 10 + i * 30), 15, col)


func _build_page_signal(p: Control) -> void:
	_lbl(p, "TELSİS SİNYAL GÜCÜ", Vector2(18, 12), 16, GREEN_DIM)
	_sig_bar = _lbl(p, "", Vector2(18, 46), 34)
	_sig_info = _lbl(p, "", Vector2(18, 108), 16, GREEN_DIM)


# ------------------------------------------------------------------ giris & durum

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_TAB and acquired:
			is_up = not is_up
		elif is_up:
			match event.physical_keycode:
				KEY_1: _set_tab(0)
				KEY_2: _set_tab(1)
				KEY_3: _set_tab(2)
				KEY_4: _set_tab(3)
	elif is_up and _tab == 1 and event is InputEventMouseButton \
			and event.pressed and event.button_index == MOUSE_BUTTON_LEFT \
			and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_do_scan()


func _set_tab(i: int) -> void:
	_tab = i
	for k in 4:
		_tab_btns[k].add_theme_color_override("font_color",
				GREEN if k == i else GREEN_DIM)
		_pages[k].visible = k == i


func _do_scan() -> void:
	if _scan_busy:
		return
	if battery < 4.0:
		_scan_status.text = "BATARYA YETERSİZ"
		_scan_status.add_theme_color_override("font_color", AMBER)
		return
	_scan_busy = true
	battery -= 4.0
	awareness = minf(awareness + 7.0, 100.0)
	_scan_result.text = ""
	_scan_status.add_theme_color_override("font_color", GREEN)
	for i in 3:
		_scan_status.text = "TARANIYOR" + ".".repeat(i + 1)
		await get_tree().create_timer(0.45).timeout
	# kamera merkezinden isin; "scan_ignore" isaretli gorunmez engelleri atla
	var cam := get_viewport().get_camera_3d()
	var from := cam.global_position
	var to := from - cam.global_transform.basis.z * 6.0
	var q := PhysicsRayQueryParameters3D.create(from, to)
	var hit := {}
	for _i in 5:
		hit = get_world_3d().direct_space_state.intersect_ray(q)
		if hit.is_empty() or not _scan_meta_ignored(hit.collider):
			break
		q.exclude = q.exclude + [(hit.collider as CollisionObject3D).get_rid()]
		hit = {}
	_scan_status.text = "HAZIR"
	if hit.is_empty():
		_scan_result.text = "> HEDEF YOK"
		_scan_result.add_theme_color_override("font_color", GREEN_DIM)
	elif _scan_in_group(hit.collider, "unreadable"):
		_scan_result.text = "> OKUNAMIYOR"
		_scan_result.add_theme_color_override("font_color", Color(0.9, 0.3, 0.25))
		awareness = minf(awareness + 14.0, 100.0)
		get_tree().call_group("quest_mgr", "on_yolcu_scanned", hit.collider)
	elif _scan_in_group(hit.collider, "anomaly"):
		_scan_result.text = "> UYUMSUZ"
		_scan_result.add_theme_color_override("font_color", AMBER)
		awareness = minf(awareness + 10.0, 100.0)
		get_tree().call_group("quest_mgr", "on_anomaly_scanned", hit.collider)
	else:
		_scan_result.text = "> NORMAL"
		_scan_result.add_theme_color_override("font_color", GREEN)
	_scan_busy = false


## Grup uyeligini ata dugumlerde de ara (GLB sahnelerinde collider cocukta kalir)
func _scan_in_group(n: Node, g: String) -> bool:
	var cur := n
	while cur != null:
		if cur.is_in_group(g):
			return true
		cur = cur.get_parent()
	return false


func _scan_meta_ignored(n: Node) -> bool:
	var cur := n
	while cur != null:
		if cur.has_meta("scan_ignore"):
			return true
		cur = cur.get_parent()
	return false


func _process(delta: float) -> void:
	_t += delta
	# kaldir/indir animasyonu
	# kamera donusune gecikmeli takip (dogal el sallantisi)
	var par := get_parent() as Node3D
	if par:
		var gb := par.global_transform.basis
		var dq := (_prev_pbasis.inverse() * gb).get_euler()
		_prev_pbasis = gb
		_lag = _lag.lerp(Vector2(dq.y, dq.x) * 5.0, 1.0 - exp(-9.0 * delta))
		_lag = _lag.limit_length(0.045)

	var tp := POS_UP if is_up else POS_DOWN
	var tr := ROT_UP if is_up else ROT_DOWN
	if is_up:
		# idle: nefes + organik mikro salinim + sway
		tp += Vector3(
				_idle_noise.get_noise_1d(_t * 0.55) * 0.0035,
				sin(_t * 1.35) * 0.0026 + _idle_noise.get_noise_1d(_t * 0.4 + 100.0) * 0.0028,
				0.0)
		tp += Vector3(-_lag.x * 0.6, _lag.y * 0.6, 0.0)
		tr += Vector3(_lag.y * 1.4 + _idle_noise.get_noise_1d(_t * 0.5 + 50.0) * 0.015,
				_lag.x * 1.2,
				_idle_noise.get_noise_1d(_t * 0.35 + 200.0) * 0.012)
	position = position.lerp(tp, 1.0 - exp(-10.0 * delta))
	rotation = rotation.lerp(tr, 1.0 - exp(-10.0 * delta))
	# once ekrandan tamamen ciksin, ancak ondan sonra gizlensin (ani pop olmasin)
	visible = is_up or position.distance_to(POS_DOWN) > 0.015
	var glow := get_node_or_null("ScreenGlow") as OmniLight3D
	if glow:
		glow.light_energy = lerpf(glow.light_energy, 0.22 if is_up else 0.0,
				1.0 - exp(-8.0 * delta))
	if not is_up:
		return

	# dikkat yavas soner
	awareness = maxf(awareness - delta * 1.2, 0.0)
	_aw_fill.size.x = (SCREEN_W - 150) * awareness / 100.0
	_aw_fill.color = GREEN if awareness < 60.0 else AMBER

	# saat + batarya (batarya cok yavas kendiliginden azalir)
	battery = maxf(battery - delta * 0.03, 0.0)
	_batt_lbl.text = "BAT %d%%" % int(battery)
	_batt_lbl.add_theme_color_override("font_color",
			GREEN if battery > 25.0 else AMBER)
	var mins := int(_t / 60.0)
	_clock_lbl.text = "23:%02d" % (41 + mins) if mins < 19 else "00:%02d" % (mins - 19)

	# okumalar: gurultulu, yavas suzulen degerler; hat gurultusu muzik enerjisiyle artar
	if Engine.get_frames_drawn() % 8 == 0:
		var main := get_tree().current_scene
		var tension := 0.0
		if main and main.get("_tension_lvl") != null:
			tension = float(main.get("_tension_lvl"))
		_read_lbls["BASINÇ"].text = "%.1f" % (1013.2 + sin(_t * 0.11) * 1.3
				+ randf_range(-0.4, 0.4))
		_read_lbls["SICAKLIK"].text = "%.1f" % (13.8 + sin(_t * 0.07) * 0.4
				+ randf_range(-0.1, 0.1))
		var noise_db := -52.0 + tension * 14.0 + randf_range(-1.5, 1.5)
		var nl: Label = _read_lbls["HAT GÜRÜLTÜSÜ"]
		nl.text = "%.1f" % noise_db
		nl.add_theme_color_override("font_color", GREEN if noise_db < -44.0 else AMBER)

	# sinyal: peronda tam, merdivende zayif, ust koridorda olu bolge
	if _tab == 3:
		var pl := get_tree().get_first_node_in_group("player") as Node3D
		var sig := 5
		if pl:
			if pl.global_position.z < -4.0:
				sig = 0
			elif pl.global_position.z < 0.0 or pl.global_position.y > 0.8:
				sig = 2
		_sig_bar.text = "█".repeat(sig) + "░".repeat(5 - sig)
		_sig_bar.add_theme_color_override("font_color",
				GREEN if sig >= 3 else (AMBER if sig > 0 else Color(0.8, 0.25, 0.2)))
		_sig_info.text = ["ÖLÜ BÖLGE — bağlantı yok", "sinyal zayıf",
				"sinyal zayıf", "bağlantı iyi", "bağlantı iyi",
				"bağlantı güçlü"][sig]
