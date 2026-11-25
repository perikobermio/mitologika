extends Node2D
## Sombras del abade proyectadas por las luces cercanas (farolas, velas).
##
## Cada sombra es una copia del fotograma actual del abade, en negro
## semitransparente, tumbada sobre el suelo desde sus pies y en sentido
## contrario a la luz. Cerca de la luz es corta y marcada; al alejarse se
## alarga y se va atenuando poco a poco hasta desaparecer. Con dos luces
## cerca hay dos sombras: la de la luz principal y otra más tenue.
## Sigue el parpadeo de cada luz.
##
## La escena puede tener `intensidad_sombras` (escena.gd) para hacerlas más
## suaves o más marcadas.

const OPACIDAD := 0.6
## Peso de la segunda sombra respecto a la principal.
const SECUNDARIA := 0.5
## Alcance de la sombra respecto al radio visible de la luz (se atenúa hasta ahí).
const ALCANCE := 1.8
## Longitud respecto a la altura del abade: bajo la luz y al límite del alcance.
const LARGO_MIN := 0.4
const LARGO_MAX := 1.6
const ANCHO := 0.85
## Rapidez con la que una sombra aparece o se desvanece.
const SUAVIZADO := 4.0

@export var sprite_path: NodePath = ^"../Sprite"

var _sprite: AnimatedSprite2D
var _luces: Array[PointLight2D] = []
var _sombras := {}   # luz -> Sprite2D


func _ready() -> void:
	_sprite = get_node(sprite_path)
	_buscar_luces.call_deferred()


func _buscar_luces() -> void:
	_luces.clear()
	var escena := get_tree().current_scene
	if escena:
		for n in escena.find_children("*", "PointLight2D", true, false):
			_luces.append(n)


func _process(delta: float) -> void:
	var tex: Texture2D = null
	if _sprite.sprite_frames:
		tex = _sprite.sprite_frames.get_frame_texture(_sprite.animation, _sprite.frame)
	var intensidad := 1.0
	var escena := get_tree().current_scene
	if escena and "intensidad_sombras" in escena:
		intensidad = escena.intensidad_sombras

	# Peso de cada luz: se atenúa suavemente hasta ALCANCE veces su radio.
	var pies := global_position
	var datos := {}
	var orden := []
	for luz in _luces:
		if not is_instance_valid(luz) or not luz.visible:
			continue
		var v := pies - _suelo_de(luz)
		var dist := v.length()
		var alcance := 128.0 * luz.texture_scale * absf(luz.global_scale.x) * ALCANCE
		if dist >= alcance or dist < 1.0:
			continue
		var t := dist / alcance
		var peso := pow(1.0 - t, 1.6) * clampf(luz.energy, 0.0, 1.5)
		datos[luz] = [peso, v / dist, t]
		orden.append(luz)
	orden.sort_custom(func(a, b): return datos[a][0] > datos[b][0])

	# Solo las dos luces que más pesan proyectan sombra; la segunda, más tenue.
	var objetivo := {}
	for i in mini(2, orden.size()):
		var luz = orden[i]
		objetivo[luz] = datos[luz][0] * OPACIDAD * intensidad * (1.0 if i == 0 else SECUNDARIA)

	for luz in datos:
		if not _sombras.has(luz):
			_sombras[luz] = _nueva_sombra()
	for luz in _sombras.keys():
		var s: Sprite2D = _sombras[luz]
		var alfa: float = minf(objetivo.get(luz, 0.0), OPACIDAD)
		s.modulate.a = move_toward(s.modulate.a, alfa, SUAVIZADO * delta)
		s.visible = s.modulate.a > 0.005 and tex != null
		if not s.visible:
			if not is_instance_valid(luz):
				s.queue_free()
				_sombras.erase(luz)
			continue
		if datos.has(luz):
			var d: Vector2 = datos[luz][1]
			var largo := lerpf(LARGO_MIN, LARGO_MAX, datos[luz][2])
			var esc := _sprite.scale.x
			# El "arriba" del sprite se tumba en la dirección d; el ancho, perpendicular.
			s.transform = Transform2D(Vector2(d.y, -d.x) * esc * ANCHO, -d * esc * largo, Vector2.ZERO)
		s.texture = tex
		s.offset = _sprite.offset


func _nueva_sombra() -> Sprite2D:
	var s := Sprite2D.new()
	s.centered = false
	s.modulate = Color(0, 0, 0, 0)
	s.visible = false
	add_child(s)
	return s


## Punto del suelo bajo la luz: la base de la farola si cuelga de una,
## o un poco por debajo de la llama en velas y apliques.
func _suelo_de(luz: PointLight2D) -> Vector2:
	var padre := luz.get_parent()
	if padre is Sprite2D and String(padre.name).begins_with("Farola"):
		return (padre as Node2D).global_position
	return luz.global_position + Vector2(0, 28)
