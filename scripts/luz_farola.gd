extends PointLight2D
## Parpadeo de llama, distinto en cada farola: al arrancar cada una sortea su
## propio ritmo, amplitud y frecuencia de bajones, así que nunca van a la vez.
##
## Si `inestable` está activo (plaza.gd lo sortea entre todas las farolas), el
## temblor es mucho más fuerte y la luz se apaga de vez en cuando un instante,
## a veces con chisporroteos al volver.

@export var inestable := false

var _base: float
var _ruido := FastNoiseLite.new()
var _t := 0.0
var _variacion: float
var _velocidad: float
var _bajones_por_seg: float
var _profundidad: float
var _bajon := 0.0

# Apagones (solo farola inestable)
var _hasta_apagon := 0.0
var _apagada := 0.0       # segundos que quedan apagada
var _chispazos := 0       # parpadeos al volver a encenderse


func _ready() -> void:
	_base = energy
	_ruido.seed = randi()
	_ruido.frequency = 1.0
	_t = randf() * 1000.0
	set_inestable(inestable)


func set_inestable(valor: bool) -> void:
	inestable = valor
	if inestable:
		_variacion = randf_range(0.3, 0.45)
		_velocidad = randf_range(6.0, 10.0)
		_bajones_por_seg = randf_range(0.6, 1.2)
		_profundidad = randf_range(0.5, 0.8)
		_hasta_apagon = randf_range(2.0, 7.0)
	else:
		_variacion = randf_range(0.04, 0.1)
		_velocidad = randf_range(1.2, 3.5)
		_bajones_por_seg = randf_range(0.02, 0.12)
		_profundidad = randf_range(0.1, 0.25)


func _process(delta: float) -> void:
	_t += delta * _velocidad

	if inestable and _actualizar_apagon(delta):
		energy = _base * 0.03
		return

	if _bajon <= 0.0 and randf() < delta * _bajones_por_seg:
		_bajon = randf_range(0.5, 1.0)
	_bajon = maxf(_bajon - delta * randf_range(4.0, 8.0), 0.0)
	energy = _base * maxf(1.0 + _variacion * _ruido.get_noise_1d(_t) - _profundidad * _bajon, 0.05)


## Devuelve true mientras la farola está apagada.
func _actualizar_apagon(delta: float) -> bool:
	if _apagada > 0.0:
		_apagada -= delta
		if _apagada <= 0.0:
			if _chispazos > 0:
				_hasta_apagon = randf_range(0.04, 0.15)  # vuelve un instante
			else:
				_hasta_apagon = randf_range(3.0, 12.0)   # fin de la ráfaga
		return _apagada > 0.0
	_hasta_apagon -= delta
	if _hasta_apagon <= 0.0:
		if _chispazos > 0:
			_chispazos -= 1
			_apagada = randf_range(0.03, 0.12)  # chispazo dentro de la ráfaga
		else:
			_apagada = randf_range(0.08, 0.6)   # apagón
			_chispazos = randi_range(0, 3)
		return true
	return false
