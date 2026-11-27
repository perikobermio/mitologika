extends "res://scripts/player.gd"
## Copia del abade que se mueve sola por la plaza como enemigo.
##
## Usa la misma escena, el mismo SpriteFrames, la misma colisión de los pies y
## el mismo movimiento con move_and_slide(), así que respeta exactamente los
## mismos muros y límites que el héroe. Solo cambia la toma de decisiones: en
## vez de leer el teclado, elige una dirección al azar cada pocos segundos.

@export_group("Movimiento aleatorio")
## Tiempo mínimo y máximo, en segundos, antes de elegir otra dirección.
@export var pausa_min := 0.8
@export var pausa_max := 2.8
## Probabilidad de quedarse parado al tomar una decisión.
@export_range(0.0, 1.0) var probabilidad_parar := 0.25

var _direccion := Vector2.ZERO
var _tiempo_decision := 0.0


func _ready() -> void:
	super._ready()
	_tiempo_decision = randf_range(0.0, pausa_max)
	_elegir_direccion()


## El enemigo no usa el teclado; evita además duplicar los eventos de input.
func _add_inputs() -> void:
	pass


func _elegir_direccion() -> void:
	_tiempo_decision = randf_range(pausa_min, pausa_max)
	if randf() < probabilidad_parar:
		_direccion = Vector2.ZERO
	else:
		var angulo := randf() * TAU
		_direccion = Vector2(cos(angulo), sin(angulo))


func _physics_process(delta: float) -> void:
	if usar_perspectiva:
		_actualizar_perspectiva(delta)

	_tiempo_decision -= delta
	if _tiempo_decision <= 0.0:
		_elegir_direccion()

	if _direccion == Vector2.ZERO:
		velocity = Vector2.ZERO
		_sprite.play("idle_" + DIRS[_dir])
		return

	# Misma proyección isométrica que el héroe: el movimiento vertical se ve más corto.
	velocity = Vector2(_direccion.x, _direccion.y * 0.75).normalized() * walk_speed
	move_and_slide()
	_dir = _dir_de(_direccion)
	_sprite.play("walk_" + DIRS[_dir])
