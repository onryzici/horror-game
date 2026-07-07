extends CharacterBody3D
## First-person kontrol: WASD + fare, Shift hizli.
## SAG TIK basili = dijital zoom (4x'e kadar), birakinca geri doner.
## Zoom arttikca grain + yumusama artar (dijital kirpma hissi), el sallantisi buyur.

const BASE_FOV := 70.0
const WALK_SPEED := 2.4
const FAST_SPEED := 4.2
const MOUSE_SENS := 0.0021
const ZOOM_MAX := 1.6
const ZOOM_IN_RATE := 0.9   # birim/sn (basiliyken)
const ZOOM_OUT_RATE := 2.4  # birim/sn (birakinca)

var cam: Camera3D
var sens_mult := 1.0        # ESC menusu ayarlar (%20-%300 → 0.2-3.0)
var base_fov := BASE_FOV    # ESC menusu ayarlar (60-90)
var locked := false         # CCTV vb. ekran acikken hareket/bakis kilidi
var has_flashlight := false # fener zimmet masasindan alinana kadar F calismaz
var _yaw := 0.0
var _pitch := 0.0
var _zooming := false
var _zoom := 1.0
var _bob_t := 0.0
var _sway := FastNoiseLite.new()
var _sway_t := 0.0
var _fl_pivot: Node3D          # el feneri (F) — kamerayi gecikmeli takip eder
var _flashlight: SpotLight3D
var _prev_yaw := 0.0
var _prev_pitch := 0.0
var _mb := Vector2.ZERO        # donus motion blur vektoru (ekran uzayi)

func _ready() -> void:
	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.3
	cap.height = 1.8
	col.shape = cap
	col.position.y = 0.9
	add_child(col)

	cam = Camera3D.new()
	cam.position.y = 1.62
	cam.fov = base_fov
	cam.near = 0.05
	cam.attributes = CameraAttributesPractical.new()
	add_child(cam)

	# el terminali (TAB) — diegetic HUD, kameraya bagli
	var term := Node3D.new()
	term.set_script(load("res://scripts/terminal.gd"))
	cam.add_child(term)

	# el feneri: dunyada serbest pivot, kamerayi yumusak takip eder (gercekci gecikme)
	_fl_pivot = Node3D.new()
	add_child(_fl_pivot)
	_flashlight = SpotLight3D.new()
	_flashlight.position = Vector3(0.22, -0.16, 0.05)
	_flashlight.light_color = Color(1.0, 0.93, 0.8)
	_flashlight.light_energy = 3.4
	_flashlight.spot_range = 17.0
	_flashlight.spot_angle = 31.0
	_flashlight.spot_angle_attenuation = 1.3
	_flashlight.shadow_enabled = true
	_flashlight.shadow_blur = 1.2
	_flashlight.visible = false
	_fl_pivot.add_child(_flashlight)

	_sway.seed = 7
	_sway.frequency = 0.9
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func set_view(yaw_deg: float, pitch_deg: float) -> void:
	_yaw = deg_to_rad(yaw_deg)
	_pitch = deg_to_rad(pitch_deg)


## Fener gucu: false = ciliz (pil bitmis), true = tam guc (pil takili)
func set_flashlight_power(full: bool) -> void:
	if _flashlight == null:
		return
	_flashlight.light_energy = 3.4 if full else 0.7
	_flashlight.spot_range = 17.0 if full else 7.0

func _unhandled_input(event: InputEvent) -> void:
	if locked:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var sens := MOUSE_SENS * sens_mult / sqrt(_zoom)
		_yaw -= event.relative.x * sens
		_pitch = clampf(_pitch - event.relative.y * sens, -1.45, 1.45)
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
				_zooming = event.pressed
			elif event.pressed:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		elif event.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event is InputEventKey and event.pressed and not event.echo:
		# ESC artik pause_menu.gd'de — burada ele alinmaz
		if event.physical_keycode == KEY_F and has_flashlight:
			_flashlight.visible = not _flashlight.visible
		elif event.physical_keycode == KEY_E:
			var t := _aim_target()
			if t and t.has_meta("on_interact"):
				(t.get_meta("on_interact") as Callable).call()


## Kameranin bakis dogrultusundaki etkilesilebilir nesne (2.4 m menzil)
func _aim_target() -> Node:
	if cam == null:
		return null
	var from := cam.global_position
	var to := from - cam.global_transform.basis.z * 2.4
	var q := PhysicsRayQueryParameters3D.create(from, to, 0xFFFFFFFF, [get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	if hit.is_empty():
		return null
	var c := hit.collider as Node
	return c if c.is_in_group("interactable") else null

func _physics_process(delta: float) -> void:
	var dir := Vector3.ZERO
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and not locked:
		var f := -Vector3(sin(_yaw), 0, cos(_yaw))
		var r := Vector3(cos(_yaw), 0, -sin(_yaw))
		if Input.is_physical_key_pressed(KEY_W):
			dir += f
		if Input.is_physical_key_pressed(KEY_S):
			dir -= f
		if Input.is_physical_key_pressed(KEY_D):
			dir += r
		if Input.is_physical_key_pressed(KEY_A):
			dir -= r
	var speed := FAST_SPEED if Input.is_physical_key_pressed(KEY_SHIFT) else WALK_SPEED
	dir = dir.normalized() * speed

	velocity.x = move_toward(velocity.x, dir.x, 18.0 * delta)
	velocity.z = move_toward(velocity.z, dir.z, 18.0 * delta)
	if not is_on_floor():
		velocity.y -= 12.0 * delta
	else:
		velocity.y = -1.0
	move_and_slide()

func _process(delta: float) -> void:
	# dijital zoom: yumusak lens hissi — hedefe ussel yaklasma, ani hareket yok
	var zoom_target := ZOOM_MAX if _zooming else 1.0
	_zoom = lerpf(_zoom, zoom_target, 1.0 - exp(-5.5 * delta))
	cam.fov = rad_to_deg(2.0 * atan(tan(deg_to_rad(base_fov * 0.5)) / _zoom))

	# bas sallanmasi (yurume) + zoomda el titremesi
	var hspeed := Vector2(velocity.x, velocity.z).length()
	_bob_t += delta * hspeed * 4.2
	_sway_t += delta
	var move_f := clampf(hspeed / WALK_SPEED, 0.0, 1.0)
	var run_f := clampf((hspeed - WALK_SPEED) / (FAST_SPEED - WALK_SPEED), 0.0, 1.0)

	# sade sallanti: cok hafif, kosarken az belirgin
	var bob_amp := lerpf(0.007, 0.017, run_f) * move_f
	var bob_y := sin(_bob_t) * bob_amp
	var bob_x := cos(_bob_t * 0.5) * bob_amp * 0.5
	var roll := cos(_bob_t * 0.5) * (0.002 + 0.004 * run_f) * move_f
	# zoom sallantisi cok hafif
	var sway_amp := (_zoom - 1.0) * 0.0005
	var sx := _sway.get_noise_1d(_sway_t * 14.0) * sway_amp
	var sy := _sway.get_noise_1d(_sway_t * 14.0 + 500.0) * sway_amp

	cam.position.y = 1.62 + bob_y
	cam.position.x = bob_x
	cam.rotation = Vector3(_pitch + sy, 0, roll)
	rotation.y = _yaw + sx

	# donus motion blur: kamera acisal hizina bagli, yumusatilmis
	var dy := wrapf(_yaw - _prev_yaw, -PI, PI)
	var dp := _pitch - _prev_pitch
	_prev_yaw = _yaw
	_prev_pitch = _pitch
	var mb_target := Vector2(dy, dp) * 0.38
	mb_target = mb_target.limit_length(0.018)
	_mb = _mb.lerp(mb_target, 1.0 - exp(-18.0 * delta))

	# el feneri kamerayi yumusak takip eder (hafif surtunmeli his)
	if _fl_pivot:
		_fl_pivot.top_level = true
		_fl_pivot.global_transform = _fl_pivot.global_transform.interpolate_with(
				cam.global_transform, 1.0 - exp(-13.0 * delta))

	# post shader baglantisi
	var fx := get_tree().get_first_node_in_group("post_fx")
	if fx and fx is ColorRect and fx.material is ShaderMaterial:
		var zn := clampf((_zoom - 1.0) / (ZOOM_MAX - 1.0), 0.0, 1.0)
		# temiz zoom: sadece hafif grain artisi, baska efekt yok
		fx.material.set_shader_parameter("zoom_grain", zn * 0.02)
		fx.material.set_shader_parameter("zoom_pixelate", 0.0)
		fx.material.set_shader_parameter("motion_blur", _mb)
	var lbl := get_tree().get_first_node_in_group("zoom_label")
	if lbl and lbl is Label:
		lbl.visible = _zoom > 1.05
		lbl.text = "ZOOM %.1fx" % _zoom

	# etkilesim gostergesi: tus kutusu + eylem metni (main.gd kurar)
	var ip := get_tree().get_first_node_in_group("interact_panel")
	var it := get_tree().get_first_node_in_group("interact_text")
	if ip and it is Label:
		var tgt := _aim_target()
		ip.visible = tgt != null and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
		if tgt:
			# prompt "[E]  METIN" — tus kutusu sabit, yalniz eylem metnini goster
			var p := str(tgt.get_meta("prompt", ""))
			it.text = p.replace("[E]  ", "").replace("[E] ", "").replace("[E]", "")
