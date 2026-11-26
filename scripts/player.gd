extends CharacterBody2D
## ABADEA: camina en 8 direcciones con los cursores y ataca con espacio.
## El origen del nodo son sus pies (para el Y Sort) y la colisión es una pequeña
## forma en los pies.
##
## Sprites en res://assets/characters/ABADEA/<anim>/ABADEA_<anim>_<dir>.png, cada
## uno con su .json (PixelOver) que da los rectángulos de frame y los fps.

const DIRS: Array[String] = ["n", "ne", "e", "se", "s", "so", "o", "no"]  # sentido horario
const RUTA := "res://assets/characters/ABADEA/%s/ABADEA_%s_%s"
const ANIMS := {"idle": true, "walk": true, "attack": false}  # nombre -> en bucle
## Zona útil de cada frame de 512x512 (el resto es transparente) y punto de los pies.
const RECORTE := Rect2i(128, 96, 256, 208)
const PIES := Vector2(256, 264)

@export var speed := 110.0

@export_group("Perspectiva")
## Si está activo, el abade cambia de tamaño según su profundidad en la escena.
@export var usar_perspectiva := false
## Escala del abade en la parte más lejana y en la más cercana del escenario.
## Se interpola según su altura en pantalla para acompañar la profundidad del dibujo.
@export var escala_lejos := 0.72
@export var escala_cerca := 1.05
## Franja del fondo (0 = borde superior, 1 = borde inferior) donde se aplica el cambio.
@export_range(0.0, 1.0) var banda_lejos := 0.30
@export_range(0.0, 1.0) var banda_cerca := 0.95
## Rapidez con la que el tamaño se adapta al moverse.
@export var suavizado := 8.0

var _dir := 4  # mirando al sur
var _atacando := false
var _alto_mundo := 576.0
## Escala actual por perspectiva (la usa escena.gd para la caja de oclusión).
var factor_perspectiva := 1.0

@onready var _sprite: AnimatedSprite2D = $Visual/Sprite
@onready var _visual: Node2D = $Visual


func _ready() -> void:
	_build_frames()
	_add_inputs()
	_sprite.centered = false
	_sprite.offset = Vector2(RECORTE.position) - PIES
	_sprite.animation_finished.connect(func(): _atacando = false)
	_sprite.play("idle_" + DIRS[_dir])
	_alto_mundo = _alto_del_mundo()
	factor_perspectiva = _escala_para(global_position.y) if usar_perspectiva else 1.0
	_visual.scale = Vector2.ONE * factor_perspectiva


func _physics_process(delta: float) -> void:
	if usar_perspectiva:
		_actualizar_perspectiva(delta)
	if _atacando:
		velocity = Vector2.ZERO
		return
	var input := _leer_movimiento()
	if Input.is_action_just_pressed("atacar"):
		if input != Vector2.ZERO:
			_dir = _dir_de(input)
		_atacando = true
		_sprite.play("attack_" + DIRS[_dir])
		return

	# Proyección isométrica: el movimiento vertical se ve más corto.
	velocity = Vector2(input.x, input.y * 0.75).normalized() * speed
	move_and_slide()

	if input == Vector2.ZERO:
		_sprite.play("idle_" + DIRS[_dir])
	else:
		_dir = _dir_de(input)
		_sprite.play("walk_" + DIRS[_dir])


## Orienta al abade (0 n ... 7 no) sin moverlo.
func mirar(dir: int) -> void:
	_dir = wrapi(dir, 0, 8)
	if _sprite.sprite_frames:
		_sprite.play("idle_" + DIRS[_dir])


func _dir_de(input: Vector2) -> int:
	return wrapi(roundi(atan2(input.x, -input.y) / (PI / 4.0)), 0, 8)


## Lee el movimiento con teclas físicas (flechas y WASD). Así no le afectan
## teclas lógicas que X11 pueda dejar pulsadas, como el 6 del teclado numérico.
func _leer_movimiento() -> Vector2:
	var v := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_LEFT) or Input.is_physical_key_pressed(KEY_A):
		v.x -= 1.0
	if Input.is_physical_key_pressed(KEY_RIGHT) or Input.is_physical_key_pressed(KEY_D):
		v.x += 1.0
	if Input.is_physical_key_pressed(KEY_UP) or Input.is_physical_key_pressed(KEY_W):
		v.y -= 1.0
	if Input.is_physical_key_pressed(KEY_DOWN) or Input.is_physical_key_pressed(KEY_S):
		v.y += 1.0
	return v


## Ajusta el tamaño del abade a la profundidad del punto del suelo donde está.
func _actualizar_perspectiva(delta: float) -> void:
	var objetivo := _escala_para(global_position.y)
	factor_perspectiva = lerpf(factor_perspectiva, objetivo, 1.0 - exp(-suavizado * delta))
	_visual.scale = Vector2.ONE * factor_perspectiva


func _escala_para(y: float) -> float:
	var t := clampf(inverse_lerp(banda_lejos, banda_cerca, y / _alto_mundo), 0.0, 1.0)
	return lerpf(escala_lejos, escala_cerca, t)


## Alto del escenario: el del fondo, que ocupa todo el mundo jugable.
func _alto_del_mundo() -> float:
	var raiz := get_tree().current_scene
	if raiz == null:
		raiz = self
		while raiz.get_parent() and raiz.get_parent() != get_tree().root:
			raiz = raiz.get_parent()
	var fondo: Sprite2D = raiz.get_node_or_null("Fondo") as Sprite2D
	if fondo and fondo.texture:
		return fondo.texture.get_height() * absf(fondo.global_scale.y)
	return float(ProjectSettings.get_setting("display/window/size/viewport_height", 756))


func _build_frames() -> void:
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	for anim in ANIMS:
		for dir in DIRS:
			var nombre: String = anim + "_" + dir
			var base := RUTA % [anim, anim, dir]
			var datos: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(base + ".json"))
			var hoja: Image = load(base + ".png").get_image()
			sf.add_animation(nombre)
			sf.set_animation_loop(nombre, ANIMS[anim])
			sf.set_animation_speed(nombre, datos.meta.frameAnimations[0].fps)
			for f in datos.frames:
				var r := Rect2i(int(f.frame.x), int(f.frame.y), int(f.frame.w), int(f.frame.h))
				var zona := Rect2i(r.position + RECORTE.position, RECORTE.size)
				sf.add_frame(nombre, ImageTexture.create_from_image(hoja.get_region(zona)))
	_sprite.sprite_frames = sf


func _add_inputs() -> void:
	# Cursores ya están en ui_*; se añade WASD como alternativa.
	var keys := {"ui_left": KEY_A, "ui_right": KEY_D, "ui_up": KEY_W, "ui_down": KEY_S}
	for action in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = keys[action]
		InputMap.action_add_event(action, ev)
	if not InputMap.has_action("atacar"):
		InputMap.add_action("atacar")
		var esp := InputEventKey.new()
		esp.physical_keycode = KEY_SPACE
		InputMap.action_add_event("atacar", esp)
