extends PointLight2D
## Parpadeo suave de llama: la intensidad oscila con ruido y, de vez en cuando,
## baja un instante.

@export var variacion := 0.12
@export var velocidad := 2.5

var _base: float
var _ruido := FastNoiseLite.new()
var _t := 0.0
var _bajon := 0.0


func _ready() -> void:
	_base = energy
	_ruido.seed = randi()
	_ruido.frequency = 1.0
	_t = randf() * 100.0


func _process(delta: float) -> void:
	_t += delta * velocidad
	if _bajon <= 0.0 and randf() < delta * 0.15:
		_bajon = 1.0
	_bajon = maxf(_bajon - delta * 6.0, 0.0)
	energy = _base * (1.0 + variacion * _ruido.get_noise_1d(_t) - 0.25 * _bajon)
