extends PointLight2D
## Luz de vela: titileo rápido e irregular, pequeños vaivenes de la llama
## (la luz se desplaza un poco) y, de vez en cuando, un parpadeo por corriente.
## Cada vela sortea su propio ritmo al arrancar, así que nunca van a la vez.

var _base_energia: float
var _base_pos: Vector2
var _base_escala: float
var _ruido := FastNoiseLite.new()
var _t := 0.0
var _velocidad: float
var _variacion: float
var _vaiven: float
var _soplo := 0.0


func _ready() -> void:
	_base_energia = energy
	_base_pos = position
	_base_escala = texture_scale
	_ruido.seed = randi()
	_ruido.frequency = 1.0
	_t = randf() * 1000.0
	_velocidad = randf_range(7.0, 13.0)
	_variacion = randf_range(0.15, 0.28)
	_vaiven = randf_range(0.6, 1.4)


func _process(delta: float) -> void:
	_t += delta * _velocidad
	# Corriente de aire ocasional: la llama se agacha un instante.
	if _soplo <= 0.0 and randf() < delta * 0.08:
		_soplo = randf_range(0.5, 1.0)
	_soplo = maxf(_soplo - delta * randf_range(2.0, 4.0), 0.0)

	var n1 := _ruido.get_noise_2d(_t, 0.0)
	var n2 := _ruido.get_noise_2d(0.0, _t * 0.7)
	var chispa := randf_range(-0.04, 0.04)
	energy = _base_energia * maxf(1.0 + _variacion * n1 + chispa - 0.35 * _soplo, 0.1)
	texture_scale = _base_escala * (1.0 + 0.05 * n2 - 0.08 * _soplo)
	position = _base_pos + Vector2(n2, n1 * 0.5) * _vaiven
