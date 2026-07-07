extends CanvasLayer
## ESC duraklatma menusu — SON SEFER.
## Tam ekran, VSync, fare hassasiyeti, gorus alani (FOV) ve ana ses ayarlari.
## Ayarlar aninda uygulanir, user://settings.cfg'ye yazilir, acilista geri yuklenir.

const CFG_PATH := "user://settings.cfg"

const COL_BG := Color(0.028, 0.038, 0.042, 0.96)
const COL_BORDER := Color(0.14, 0.24, 0.2)
const COL_ACCENT := Color(0.45, 0.88, 0.62)
const COL_TEXT := Color(0.78, 0.84, 0.82)
const COL_DIM := Color(0.42, 0.48, 0.46)
const COL_TRACK := Color(0.08, 0.11, 0.1)

var _font_title: FontFile = load("res://assets/fonts/BarlowCondensed-SemiBold.ttf")
var _font_body: FontFile = load("res://assets/fonts/Barlow-Medium.ttf")
var _font_semi: FontFile = load("res://assets/fonts/Barlow-SemiBold.ttf")
var _panel_box: PanelContainer

const DEF_FULLSCREEN := false
const DEF_VSYNC := true
const DEF_SENS := 100.0   # yuzde (%20-%300)
const DEF_FOV := 70.0
const DEF_VOL := 100.0    # yuzde

var _menu_open := false
var _root: Control
var _fs_check: CheckButton
var _vs_check: CheckButton
var _sens: HSlider
var _fov: HSlider
var _vol: HSlider


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_load_settings()
	_connect_apply()
	_root.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo \
			and event.physical_keycode == KEY_ESCAPE:
		_toggle()
		get_viewport().set_input_as_handled()


func _toggle() -> void:
	_menu_open = not _menu_open
	get_tree().paused = _menu_open
	_root.visible = _menu_open
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if _menu_open \
			else Input.MOUSE_MODE_CAPTURED
	if _menu_open and _panel_box:
		# yumusak giris: hafif buyume + solma (pause'da da isler)
		_root.modulate.a = 0.0
		_panel_box.scale = Vector2(0.97, 0.97)
		_panel_box.pivot_offset = _panel_box.size * 0.5
		var tw := create_tween()
		tw.tween_property(_root, "modulate:a", 1.0, 0.14)
		tw.parallel().tween_property(_panel_box, "scale", Vector2.ONE, 0.16) \
				.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)


# ------------------------------------------------------------------ UI kurulum

func _build_ui() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)

	# arka karartma: kenarlara dogru koyulasan vinyet hissi (iki katman)
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.0, 0.015, 0.015, 0.72)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(center)

	_panel_box = PanelContainer.new()
	var ps := StyleBoxFlat.new()
	ps.bg_color = COL_BG
	ps.border_color = COL_BORDER
	ps.set_border_width_all(1)
	ps.border_width_top = 3
	ps.set_corner_radius_all(10)
	ps.content_margin_left = 44.0
	ps.content_margin_right = 44.0
	ps.content_margin_top = 30.0
	ps.content_margin_bottom = 28.0
	ps.shadow_color = Color(0, 0, 0, 0.55)
	ps.shadow_size = 26
	_panel_box.add_theme_stylebox_override("panel", ps)
	center.add_child(_panel_box)

	var vb := VBoxContainer.new()
	vb.custom_minimum_size = Vector2(460, 0)
	vb.add_theme_constant_override("separation", 8)
	_panel_box.add_child(vb)

	# baslik: oyun adi buyuk, durum kucuk (acilis kartiyla ayni dil)
	var title := Label.new()
	title.text = "S O N   S E F E R"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", _font_title)
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color(0.82, 0.87, 0.85))
	vb.add_child(title)

	var sub := Label.new()
	sub.text = "HİSAR-7  ·  VARDİYA DURAKLATILDI"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_override("font", _font_body)
	sub.add_theme_font_size_override("font_size", 13)
	sub.add_theme_color_override("font_color", COL_ACCENT * Color(1, 1, 1, 0.85))
	vb.add_child(sub)

	vb.add_child(_vspace(10))
	vb.add_child(_section("GÖRÜNTÜ"))

	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 11)
	vb.add_child(grid)
	_fs_check = _add_check(grid, "Tam ekran")
	_vs_check = _add_check(grid, "Dikey eşitleme (VSync)")
	_fov = _add_slider(grid, "Görüş alanı", 60.0, 90.0, 1.0, "°")

	vb.add_child(_vspace(8))
	vb.add_child(_section("KONTROL & SES"))

	var grid2 := GridContainer.new()
	grid2.columns = 3
	grid2.add_theme_constant_override("h_separation", 20)
	grid2.add_theme_constant_override("v_separation", 11)
	vb.add_child(grid2)
	_sens = _add_slider(grid2, "Fare hassasiyeti", 20.0, 300.0, 5.0, "%")
	_vol = _add_slider(grid2, "Ana ses", 0.0, 100.0, 5.0, "%")

	vb.add_child(_vspace(14))

	# butonlar
	var bb := VBoxContainer.new()
	bb.add_theme_constant_override("separation", 8)
	vb.add_child(bb)
	bb.add_child(_btn("DEVAM ET", _toggle, true))
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	bb.add_child(hb)
	var b_reset := _btn("VARSAYILANLAR", _reset_defaults, false)
	b_reset.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(b_reset)
	var b_quit := _btn("OYUNDAN ÇIK", func() -> void: get_tree().quit(), false)
	b_quit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(b_quit)

	vb.add_child(_vspace(4))
	var hint := Label.new()
	hint.text = "ESC  devam   ·   P  fotoğraf   ·   TAB  terminal   ·   Q  telsiz"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_override("font", _font_body)
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", COL_DIM)
	vb.add_child(hint)


func _vspace(h: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c


## Bolum basligi: kucuk fosfor etiket + cizgi
func _section(text: String) -> HBoxContainer:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 12)
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", _font_semi)
	l.add_theme_font_size_override("font_size", 12)
	l.add_theme_color_override("font_color", COL_ACCENT * Color(1, 1, 1, 0.7))
	hb.add_child(l)
	var sep := HSeparator.new()
	sep.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sep.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var st := StyleBoxLine.new()
	st.color = COL_BORDER
	sep.add_theme_stylebox_override("separator", st)
	hb.add_child(sep)
	return hb


func _hsep() -> HSeparator:
	var s := HSeparator.new()
	var st := StyleBoxLine.new()
	st.color = COL_BORDER
	s.add_theme_stylebox_override("separator", st)
	return s


func _row_label(grid: GridContainer, text: String) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", _font_body)
	l.add_theme_font_size_override("font_size", 15)
	l.add_theme_color_override("font_color", COL_TEXT)
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_child(l)


func _add_check(grid: GridContainer, text: String) -> CheckButton:
	_row_label(grid, text)
	var c := CheckButton.new()
	c.size_flags_horizontal = Control.SIZE_SHRINK_END | Control.SIZE_EXPAND
	c.add_theme_color_override("icon_normal_color", COL_DIM)
	c.add_theme_color_override("icon_pressed_color", COL_ACCENT)
	c.add_theme_color_override("icon_hover_color", COL_TEXT)
	c.add_theme_color_override("icon_hover_pressed_color", COL_ACCENT)
	grid.add_child(c)
	grid.add_child(Control.new())  # deger sutunu bos
	return c


func _add_slider(grid: GridContainer, text: String, minv: float, maxv: float,
		step: float, suffix: String) -> HSlider:
	_row_label(grid, text)
	var s := HSlider.new()
	s.min_value = minv
	s.max_value = maxv
	s.step = step
	s.custom_minimum_size = Vector2(230, 22)
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	# ray: koyu ince hat; dolan kisim fosfor yesili
	var track := StyleBoxFlat.new()
	track.bg_color = COL_TRACK
	track.set_corner_radius_all(2)
	track.content_margin_top = 2.0
	track.content_margin_bottom = 2.0
	s.add_theme_stylebox_override("slider", track)
	var fill := StyleBoxFlat.new()
	fill.bg_color = COL_ACCENT * Color(1, 1, 1, 0.55)
	fill.set_corner_radius_all(2)
	s.add_theme_stylebox_override("grabber_area", fill)
	var fillh := fill.duplicate() as StyleBoxFlat
	fillh.bg_color = COL_ACCENT * Color(1, 1, 1, 0.8)
	s.add_theme_stylebox_override("grabber_area_highlight", fillh)
	grid.add_child(s)
	var v := Label.new()
	v.custom_minimum_size = Vector2(52, 0)
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	v.add_theme_font_override("font", _font_semi)
	v.add_theme_font_size_override("font_size", 15)
	v.add_theme_color_override("font_color", COL_ACCENT)
	v.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	grid.add_child(v)
	s.value_changed.connect(func(val: float) -> void:
		v.text = "%d%s" % [int(val), suffix])
	return s


func _btn(text: String, cb: Callable, primary: bool) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 42)
	b.add_theme_font_override("font", _font_semi)
	b.add_theme_font_size_override("font_size", 15)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.05, 0.09, 0.075) if primary else Color(0.045, 0.055, 0.06)
	normal.border_color = COL_ACCENT * Color(1, 1, 1, 0.6) if primary else COL_BORDER
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(6)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.08, 0.14, 0.115) if primary else Color(0.06, 0.085, 0.08)
	hover.border_color = COL_ACCENT
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(0.035, 0.05, 0.045)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.add_theme_color_override("font_color", COL_ACCENT if primary else COL_TEXT)
	b.add_theme_color_override("font_hover_color", COL_ACCENT)
	b.add_theme_color_override("font_pressed_color", COL_ACCENT * Color(1, 1, 1, 0.7))
	b.pressed.connect(cb)
	return b


# ------------------------------------------------------------------ ayar mantigi

## Kontrollerin degerlerini degistir-uygula-kaydet zincirine bagla.
## (Yukleme bittikten SONRA cagrilir ki acilista cifte kayit olmasin.)
func _connect_apply() -> void:
	_fs_check.toggled.connect(func(on: bool) -> void:
		_apply_fullscreen(on)
		_save_settings())
	_vs_check.toggled.connect(func(on: bool) -> void:
		_apply_vsync(on)
		_save_settings())
	_sens.value_changed.connect(func(v: float) -> void:
		_apply_sens(v)
		_save_settings())
	_fov.value_changed.connect(func(v: float) -> void:
		_apply_fov(v)
		_save_settings())
	_vol.value_changed.connect(func(v: float) -> void:
		_apply_vol(v)
		_save_settings())


func _reset_defaults() -> void:
	_fs_check.button_pressed = DEF_FULLSCREEN
	_vs_check.button_pressed = DEF_VSYNC
	_sens.value = DEF_SENS
	_fov.value = DEF_FOV
	_vol.value = DEF_VOL


func _apply_fullscreen(on: bool) -> void:
	DisplayServer.window_set_mode(
			DisplayServer.WINDOW_MODE_FULLSCREEN if on
			else DisplayServer.WINDOW_MODE_WINDOWED)


func _apply_vsync(on: bool) -> void:
	DisplayServer.window_set_vsync_mode(
			DisplayServer.VSYNC_ENABLED if on else DisplayServer.VSYNC_DISABLED)


func _apply_sens(v: float) -> void:
	var p := get_tree().get_first_node_in_group("player")
	if p:
		p.set("sens_mult", v / 100.0)


func _apply_fov(v: float) -> void:
	var p := get_tree().get_first_node_in_group("player")
	if p:
		p.set("base_fov", v)


func _apply_vol(v: float) -> void:
	var lin := clampf(v / 100.0, 0.0, 1.0)
	AudioServer.set_bus_volume_db(0, linear_to_db(lin) if lin > 0.001 else -80.0)


# ------------------------------------------------------------------ kayit/yukleme

func _load_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.load(CFG_PATH)  # dosya yoksa varsayilanlar kalir
	_fs_check.button_pressed = bool(cfg.get_value("display", "fullscreen", DEF_FULLSCREEN))
	_vs_check.button_pressed = bool(cfg.get_value("display", "vsync", DEF_VSYNC))
	_sens.value = float(cfg.get_value("input", "sensitivity", DEF_SENS))
	_fov.value = float(cfg.get_value("video", "fov", DEF_FOV))
	_vol.value = float(cfg.get_value("audio", "master", DEF_VOL))
	# oyuncu bir sonraki frame'de hazir olabilir — uygulamayi ertele
	call_deferred("_apply_all")


func _apply_all() -> void:
	_apply_fullscreen(_fs_check.button_pressed)
	_apply_vsync(_vs_check.button_pressed)
	_apply_sens(_sens.value)
	_apply_fov(_fov.value)
	_apply_vol(_vol.value)


func _save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("display", "fullscreen", _fs_check.button_pressed)
	cfg.set_value("display", "vsync", _vs_check.button_pressed)
	cfg.set_value("input", "sensitivity", _sens.value)
	cfg.set_value("video", "fov", _fov.value)
	cfg.set_value("audio", "master", _vol.value)
	cfg.save(CFG_PATH)
