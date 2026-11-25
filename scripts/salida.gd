extends Area2D
## Zona de salida: al pisarla el abade, se carga otra escena y aparece en `llegada`.

@export_file("*.tscn") var escena: String
@export var llegada: Vector2
## Dirección a la que mira al llegar: 0 n, 1 ne, 2 e, 3 se, 4 s, 5 so, 6 o, 7 no
@export_range(0, 7) var mirando := 4

var _usada := false


func _ready() -> void:
	body_entered.connect(_al_entrar)


func _al_entrar(cuerpo: Node2D) -> void:
	if _usada or cuerpo.name != "Abade":
		return
	_usada = true
	Viaje.ir(get_tree(), escena, llegada, mirando)
