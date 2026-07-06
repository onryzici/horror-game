extends OmniLight3D
## Floresan titremesi — surekli ince dalgalanma + nadir kisa dusus.

@export var base_energy := 3.0
@export var flicker_amount := 0.1
@export var speed := 1.0
@export var dropout_threshold := 0.75 # dusuk deger = daha sik sonme
@export var tube: MeshInstance3D
@export var buzz: AudioStreamPlayer3D  # cizirti — isikla birlikte bozulur

var blackout := false          # true iken lamba tamamen soner (olay sistemi kullanir)

var _noise := FastNoiseLite.new()
var _t := 0.0

func _ready() -> void:
	_noise.seed = randi()
	_noise.frequency = 1.0

func _process(delta: float) -> void:
	_t += delta * speed
	var n := _noise.get_noise_1d(_t * 14.0) * 0.5 + 0.5
	var e := base_energy * (1.0 - flicker_amount + flicker_amount * n)
	if _noise.get_noise_1d(_t * 4.1 + 100.0) > dropout_threshold:
		e *= 0.25
	if blackout:
		e = 0.0
	light_energy = e
	if tube and tube.material_override is StandardMaterial3D:
		var m: StandardMaterial3D = tube.material_override
		m.emission_energy_multiplier = 5.0 * (e / max(base_energy, 0.001))
	if buzz:
		# isik dustugunde cizirti da kisilir; titreme aninda hafif dalgalanir
		var ratio := e / maxf(base_energy, 0.001)
		buzz.volume_db = -34.0 + clampf(base_energy, 0.0, 3.0) * 2.0 \
				+ (ratio - 1.0) * 10.0
