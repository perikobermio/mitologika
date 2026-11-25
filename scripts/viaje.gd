class_name Viaje
## Recuerda dónde debe aparecer el abade al cambiar de escena.

static var llegada := Vector2.INF
static var mirando := 4


static func ir(arbol: SceneTree, escena: String, pos: Vector2, dir: int) -> void:
	llegada = pos
	mirando = dir
	arbol.change_scene_to_file.call_deferred(escena)
