extends CanvasLayer
## Obje INCELEME modu: bir modeli ekran ortasina getirir, arka plan bulanik,
## fare ile dondurulur (surukle), tekerlek zoom. Ofisteki lore objeleri icin.
## open(model_path, title, desc, scale) ile acilir; E/ESC/sag-tik kapatir.

var _vp: SubViewport
var _cam: Camera3D
var _pivot: Node3D            # modelin dondugu pivot
var _model: Node3D
var _layer_root: Control
var _blur: ColorRect
var _feed: TextureRect
var _title_lbl: Label
var _desc_lbl: Label
var _hint_lbl: Label
var _open := false
var _dragging := false
var _yaw := 0.0
var _pitch := 0.0
var _dist := 1.0
var _base_dist := 1.0


func _ready() -> void:
	add_to_group("examine")
	layer = 17
	process_mode = Node.PROCESS_MODE_ALWAYS

	# inceleme sahnesi: seffaf arka planli SubViewport (yalniz model gorunur)
	# KRITIK: own_world_3d = true → izole dunya. Yoksa buradaki isik/env ANA
	# sahneyi aydinlatir (karanlik ortam kaybolur) ve kamera ana sahneyi gorur
	# (arka planda merdiven vs. belirir).
	_vp = SubViewport.new()
	_vp.size = Vector2i(1280, 900)
	_vp.transparent_bg = true
	_vp.own_world_3d = true
	_vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	_vp.msaa_3d = Viewport.MSAA_4X
	add_child(_vp)
	_cam = Camera3D.new()
	_cam.fov = 42.0
	_cam.position = Vector3(0, 0, 1.0)
	_cam.near = 0.01
	_vp.add_child(_cam)
	# yumusak stüdyo isigi: iki yonlu + dolgu
	var key := DirectionalLight3D.new()
	key.rotation = Vector3(deg_to_rad(-35.0), deg_to_rad(35.0), 0.0)
	key.light_energy = 1.4
	_vp.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation = Vector3(deg_to_rad(20.0), deg_to_rad(-120.0), 0.0)
	fill.light_energy = 0.5
	fill.light_color = Color(0.8, 0.86, 1.0)
	_vp.add_child(fill)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.4, 0.42, 0.46)
	e.ambient_light_energy = 0.6
	env.environment = e
	_vp.add_child(env)
	_pivot = Node3D.new()
	_vp.add_child(_pivot)

	# ekran UI
	_layer_root = Control.new()
	_layer_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_layer_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_layer_root.visible = false
	add_child(_layer_root)

	_blur = ColorRect.new()
	_blur.set_anchors_preset(Control.PRESET_FULL_RECT)
	var bm := ShaderMaterial.new()
	bm.shader = load("res://shaders/examine_blur.gdshader")
	_blur.material = bm
	_layer_root.add_child(_blur)

	_feed = TextureRect.new()
	_feed.texture = _vp.get_texture()
	_feed.set_anchors_preset(Control.PRESET_FULL_RECT)
	_feed.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_feed.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer_root.add_child(_feed)

	var body := load("res://assets/fonts/Barlow-Medium.ttf")
	var semi := load("res://assets/fonts/Barlow-SemiBold.ttf")
	_title_lbl = Label.new()
	_title_lbl.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_title_lbl.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_title_lbl.offset_top = 60.0
	_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_lbl.add_theme_font_override("font", semi)
	_title_lbl.add_theme_font_size_override("font_size", 30)
	_title_lbl.add_theme_color_override("font_color", Color(0.9, 0.93, 0.9))
	_title_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	_title_lbl.add_theme_constant_override("outline_size", 5)
	_layer_root.add_child(_title_lbl)

	_desc_lbl = Label.new()
	_desc_lbl.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_desc_lbl.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_desc_lbl.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_desc_lbl.offset_bottom = -96.0
	_desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_desc_lbl.custom_minimum_size = Vector2(760, 0)
	_desc_lbl.add_theme_font_override("font", body)
	_desc_lbl.add_theme_font_size_override("font_size", 21)
	_desc_lbl.add_theme_color_override("font_color", Color(0.82, 0.86, 0.84))
	_desc_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	_desc_lbl.add_theme_constant_override("outline_size", 4)
	_layer_root.add_child(_desc_lbl)

	_hint_lbl = Label.new()
	_hint_lbl.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_hint_lbl.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_hint_lbl.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_hint_lbl.offset_bottom = -50.0
	_hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_lbl.add_theme_font_override("font", body)
	_hint_lbl.add_theme_font_size_override("font_size", 14)
	_hint_lbl.add_theme_color_override("font_color", Color(0.55, 0.6, 0.58))
	_hint_lbl.text = "SÜRÜKLE  döndür     ·     TEKERLEK  yakınlaş     ·     [E] / ESC  kapat"
	_layer_root.add_child(_hint_lbl)


## Modeli incele. fill: model ekranin ~bu kadarini doldurur (0.62 = %62).
func open(model_path: String, title: String, desc: String, fill := 0.62) -> void:
	if _open:
		return
	var ps: PackedScene = load(model_path)
	if ps == null:
		return
	_open = true
	if _model and is_instance_valid(_model):
		_model.queue_free()
	_model = ps.instantiate()
	_pivot.add_child(_model)
	# modeli GERCEK boyutunda tut, pivota ortala; kamerayi boyuta gore konumla
	# (boylece her model — ince pano da hacimli obje de — ekrani ayni dolulukta doldurur)
	var aabb := _node_aabb(_model, Transform3D.IDENTITY)
	_model.position = -aabb.get_center()
	var longest: float = maxf(aabb.size.x, maxf(aabb.size.y, aabb.size.z))
	var half: float = maxf(longest, 0.02) * 0.5
	_base_dist = half / tan(deg_to_rad(_cam.fov * 0.5)) / clampf(fill, 0.3, 0.9)
	_dist = _base_dist
	_yaw = 0.5
	_pitch = -0.2
	_apply_transform()

	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_title_lbl.text = title
	_desc_lbl.text = desc
	_layer_root.visible = true
	var mat := _blur.material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("amount", 1.0)
	var p := get_tree().get_first_node_in_group("player")
	if p:
		p.set("locked", true)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func close() -> void:
	if not _open:
		return
	_open = false
	_dragging = false
	_layer_root.visible = false
	_vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	if _model and is_instance_valid(_model):
		_model.queue_free()
		_model = null
	var p := get_tree().get_first_node_in_group("player")
	if p:
		p.set("locked", false)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _apply_transform() -> void:
	_pivot.rotation = Vector3(_pitch, _yaw, 0.0)
	_cam.position = Vector3(0, 0, _dist)


func _input(event: InputEvent) -> void:
	if not _open:
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			_dragging = mb.pressed
			get_viewport().set_input_as_handled()
		elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			close()
			get_viewport().set_input_as_handled()
		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			_dist = clampf(_dist - _base_dist * 0.12, _base_dist * 0.5, _base_dist * 1.8)
			_apply_transform()
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_dist = clampf(_dist + _base_dist * 0.12, _base_dist * 0.5, _base_dist * 1.8)
			_apply_transform()
	elif event is InputEventMouseMotion and _dragging:
		var mm := event as InputEventMouseMotion
		_yaw += mm.relative.x * 0.01
		_pitch = clampf(_pitch + mm.relative.y * 0.01, -1.4, 1.4)
		_apply_transform()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo:
		var k := (event as InputEventKey).physical_keycode
		if k == KEY_E or k == KEY_ESCAPE:
			close()
			get_viewport().set_input_as_handled()


## Bir dugumun toplam AABB'si (yerel uzayda)
func _node_aabb(node: Node, xf: Transform3D) -> AABB:
	var acc := AABB()
	var has := false
	var local := xf
	if node is Node3D:
		local = xf * (node as Node3D).transform
	if node is VisualInstance3D:
		var ab: AABB = local * (node as VisualInstance3D).get_aabb()
		acc = ab
		has = true
	for c in node.get_children():
		var ch := _node_aabb(c, local)
		if ch.size != Vector3.ZERO:
			if has:
				acc = acc.merge(ch)
			else:
				acc = ch
				has = true
	return acc
