extends CanvasLayer
## ESC duraklatma menusu — SON SEFER.
## Tam ekran, VSync, fare hassasiyeti, gorus alani (FOV) ve ana ses ayarlari.
## Ayarlar aninda uygulanir, user://settings.cfg'ye yazilir, acilista geri yuklenir.

const CFG_PATH := "user://settings.cfg"

const COL_BG := Color(0.035, 0.045, 0.05, 0.97)
const COL_BORDER := Color(0.16, 0.28, 0.23)
const COL_ACCENT := Color(0.45, 0.88, 0.62)
const COL_TEXT := Color(0.78, 0.84, 0.82)
const COL_DIM := Color(0.50, 0.56, 0.54)

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


# ------------------------------------------------------------------ UI kurulum

func _build_ui() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)

	# arka karartma (tiklamalari da yutar)
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.0, 0.02, 0.02, 0.62)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(center)

	var panel := PanelContainer.new()
	var ps := StyleBoxFlat.new()
	ps.bg_color = COL_BG
	ps.border_color = COL_BORDER
	ps.set_border_width_all(1)
	ps.set_corner_radius_all(8)
	ps.content_margin_left = 34.0
	ps.content_margin_right = 34.0
	ps.content_margin_top = 26.0
	ps.content_margin_bottom = 26.0
	panel.add_theme_stylebox_override("panel", ps)
	center.add_child(panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	panel.add_child(vb)

	# baslik
	var title := Label.new()
	title.text = "DURAKLATILDI"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", COL_ACCENT)
	vb.add_child(title)

	var sub := Label.new()
	sub.text = "SON SEFER  —  HİSAR-7"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 12)
	sub.add_theme_color_override("font_color", COL_DIM)
	vb.add_child(sub)

	vb.add_child(_hsep())

	# ayar tablosu: etiket | kontrol | deger
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 12)
	vb.add_child(grid)

	_fs_check = _add_check(grid, "TAM EKRAN")
	_vs_check = _add_check(grid, "DİKEY EŞİTLEME (VSYNC)")
	_sens = _add_slider(grid, "FARE HASSASİYETİ", 20.0, 300.0, 5.0, "%")
	_fov = _add_slider(grid, "GÖRÜŞ ALANI (FOV)", 60.0, 90.0, 1.0, "°")
	_vol = _add_slider(grid, "ANA SES", 0.0, 100.0, 5.0, "%")

	vb.add_child(_hsep())

	# butonlar
	var bb := VBoxContainer.new()
	bb.add_theme_constant_override("separation", 8)
	vb.add_child(bb)
	bb.add_child(_btn("DEVAM ET", _toggle, true))
	bb.add_child(_btn("VARSAYILANLARA DÖN", _reset_defaults, false))
	bb.add_child(_btn("OYUNDAN ÇIK", func() -> void: get_tree().quit(), false))

	var hint := Label.new()
	hint.text = "ESC — devam et"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", COL_DIM)
	vb.add_child(hint)


func _hsep() -> HSeparator:
	var s := HSeparator.new()
	var st := StyleBoxLine.new()
	st.color = COL_BORDER
	s.add_theme_stylebox_override("separator", st)
	return s


func _row_label(grid: GridContainer, text: String) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 14)
	l.add_theme_color_override("font_color", COL_TEXT)
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	grid.add_child(l)


func _add_check(grid: GridContainer, text: String) -> CheckButton:
	_row_label(grid, text)
	var c := CheckButton.new()
	c.size_flags_horizontal = Control.SIZE_SHRINK_END | Control.SIZE_EXPAND
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
	s.custom_minimum_size = Vector2(280, 0)
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	grid.add_child(s)
	var v := Label.new()
	v.custom_minimum_size = Vector2(56, 0)
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	v.add_theme_font_size_override("font_size", 14)
	v.add_theme_color_override("font_color", COL_ACCENT)
	v.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	grid.add_child(v)
	s.value_changed.connect(func(val: float) -> void:
		v.text = "%d%s" % [int(val), suffix])
	return s


func _btn(text: String, cb: Callable, primary: bool) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 40)
	b.add_theme_font_size_override("font_size", 15)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.06, 0.085, 0.08) if primary else Color(0.05, 0.06, 0.065)
	normal.border_color = COL_ACCENT * Color(1, 1, 1, 0.55) if primary else COL_BORDER
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(5)
	var hover := normal.duplicate()
	hover.bg_color = Color(0.09, 0.14, 0.12)
	hover.border_color = COL_ACCENT
	var pressed := normal.duplicate()
	pressed.bg_color = Color(0.04, 0.05, 0.05)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.add_theme_color_override("font_color", COL_ACCENT if primary else COL_TEXT)
	b.add_theme_color_override("font_hover_color", COL_ACCENT)
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
