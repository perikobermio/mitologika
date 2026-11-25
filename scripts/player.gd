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

var _dir := 4  # mirando al sur
var _atacando := false

@onready var _sprite: AnimatedSprite2D = $Sprite


func _ready() -> void:
	_build_frames()
	_add_inputs()
	_sprite.centered = false
	_sprite.offset = Vector2(RECORTE.position) - PIES
	_sprite.animation_finished.connect(func(): _atacando = false)
	_sprite.play("idle_" + DIRS[_dir])


func _physics_process(_delta: float) -> void:
	if _atacando:
		velocity = Vector2.ZERO
		return
	var input := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
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


func _dir_de(input: Vector2) -> int:
	return wrapi(roundi(atan2(input.x, -input.y) / (PI / 4.0)), 0, 8)


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
