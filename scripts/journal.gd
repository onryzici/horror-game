extends CanvasLayer
## GOREV GUNLUGU — masadan alinan not defteri (envanter). J ile acilir/kapanir.
## Aktif gorevleri listeler; tamamlananlarin ustu cizili + soluk. Gorev verisi
## main.gd'de tutulur (grup "quest_mgr" -> _journal_tasks); her acilista okunur.

var acquired := false          # not defteri alinana kadar J calismaz
var _open := false
var _layer_root: Control
var _list: RichTextLabel
var _hint_pulse := 0.0
var _hint: Label


func _ready() -> void:
	add_to_group("journal")
	layer = 19
	process_mode = Node.PROCESS_MODE_ALWAYS

	_layer_root = Control.new()
	_layer_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_layer_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_layer_root.visible = false
	add_child(_layer_root)

	# arka karartma (defter havasi — koyu, hafif sicak)
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.03, 0.03, 0.035, 0.82)
	_layer_root.add_child(dim)

	# defter paneli: ortada, eski kagit tonlu
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_layer_root.add_child(center)
	var panel := PanelContainer.new()
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.13, 0.12, 0.10, 0.98)
	ps.border_color = Color(0.32, 0.28, 0.2)
	ps.set_border_width_all(1)
	ps.set_corner_radius_all(6)
	ps.content_margin_left = 44.0
	ps.content_margin_right = 44.0
	ps.content_margin_top = 30.0
	ps.content_margin_bottom = 30.0
	ps.shadow_color = Color(0, 0, 0, 0.5)
	ps.shadow_size = 20
	panel.add_theme_stylebox_override("panel", ps)
	center.add_child(panel)

	var vb := VBoxContainer.new()
	vb.custom_minimum_size = Vector2(560, 0)
	vb.add_theme_constant_override("separation", 14)
	panel.add_child(vb)

	var head := Label.new()
	head.text = "GÖREV GÜNLÜĞÜ"
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_theme_font_override("font", load("res://assets/fonts/BarlowCondensed-SemiBold.ttf"))
	head.add_theme_font_size_override("font_size", 34)
	head.add_theme_color_override("font_color", Color(0.82, 0.76, 0.6))
	vb.add_child(head)

	var sep := HSeparator.new()
	var st := StyleBoxLine.new()
	st.color = Color(0.32, 0.28, 0.2)
	sep.add_theme_stylebox_override("separator", st)
	vb.add_child(sep)

	_list = RichTextLabel.new()
	_list.bbcode_enabled = true
	_list.fit_content = true
	_list.custom_minimum_size = Vector2(560, 240)
	_list.add_theme_font_override("normal_font", load("res://assets/fonts/Barlow-Medium.ttf"))
	_list.add_theme_font_override("bold_font", load("res://assets/fonts/Barlow-SemiBold.ttf"))
	_list.add_theme_font_size_override("normal_font_size", 21)
	_list.add_theme_font_size_override("bold_font_size", 21)
	vb.add_child(_list)

	var foot := Label.new()
	foot.text = "J  kapat"
	foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	foot.add_theme_font_override("font", load("res://assets/fonts/Barlow-Medium.ttf"))
	foot.add_theme_font_size_override("font_size", 13)
	foot.add_theme_color_override("font_color", Color(0.5, 0.46, 0.38))
	vb.add_child(foot)

	# "J: günlük" ipucu (defter alininca ekranin sag altinda kisa sure)
	_hint = Label.new()
	_hint.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_hint.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_hint.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_hint.offset_right = -34.0
	_hint.offset_bottom = -34.0
	_hint.add_theme_font_override("font", load("res://assets/fonts/Barlow-SemiBold.ttf"))
	_hint.add_theme_font_size_override("font_size", 17)
	_hint.add_theme_color_override("font_color", Color(0.82, 0.78, 0.62, 0.9))
	_hint.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	_hint.add_theme_constant_override("outline_size", 5)
	_hint.text = "[J]  Görev günlüğü"
	_hint.visible = false
	add_child(_hint)


## main.gd cagirir: not defteri alindi, J aktif + kisa ipucu goster
func acquire() -> void:
	if acquired:
		return
	acquired = true
	_hint.visible = true
	_hint_pulse = 0.0
	get_tree().create_timer(6.0).timeout.connect(func() -> void:
		if _hint:
			_hint.visible = false)


func _refresh() -> void:
	var mgr := get_tree().get_first_node_in_group("quest_mgr")
	if mgr == null:
		return
	var tasks: Array = mgr.get("_journal_tasks")
	var txt := ""
	var any_active := false
	for t in tasks:
		var done: bool = bool(t[1])
		if done:
			txt += "[color=#5a6b52]  ✓  [s]%s[/s][/color]\n" % str(t[0])
		else:
			txt += "[color=#e8dcc0]  ▸  [b]%s[/b][/color]\n" % str(t[0])
			any_active = true
	if tasks.is_empty():
		txt = "[color=#6b6558]  Henüz görev yok.[/color]"
	elif not any_active:
		txt += "\n[color=#5a6b52]  Tüm görevler tamam.[/color]"
	_list.text = txt


func _toggle() -> void:
	_open = not _open
	if _open:
		_refresh()
	_layer_root.visible = _open
	get_tree().paused = _open
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if _open else Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if not acquired:
		return
	if event is InputEventKey and event.pressed and not event.echo \
			and event.physical_keycode == KEY_J:
		_toggle()
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if _hint and _hint.visible and not _open:
		_hint_pulse += delta
		_hint.modulate.a = 0.55 + 0.45 * (0.5 + 0.5 * sin(_hint_pulse * 3.0))
