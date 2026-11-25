extends Node2D
## Cuando el abade queda detrás de algo grande (grupo "ocluye": el quiosco o un
## edificio), ese objeto se vuelve semitransparente para no perderlo de vista.

const ALFA_OCULTO := 0.3
const VELOCIDAD := 6.0
## Caja del abade respecto a sus pies (origen).
const CAJA_ABADE := Rect2(-12, -46, 24, 44)

@onready var _abade: Node2D = $Mundo/Abade
var _imagenes := {}

func _process(delta: float) -> void:
	var caja := Rect2(_abade.global_position + CAJA_ABADE.position, CAJA_ABADE.size)
	for nodo in get_tree().get_nodes_in_group("ocluye"):
		var detras := false
		if nodo is Sprite2D:
			detras = _tapa(nodo, caja)
		else:
			for hijo in nodo.get_children():
				if hijo is Sprite2D and _tapa(hijo, caja):
					detras = true
					break
		var objetivo := ALFA_OCULTO if detras else 1.0
		nodo.modulate.a = move_toward(nodo.modulate.a, objetivo, VELOCIDAD * delta)

## ¿El sprite se dibuja delante del abade y tiene píxeles opacos encima de él?
func _tapa(spr: Sprite2D, caja: Rect2) -> bool:
	if _abade.global_position.y >= spr.global_position.y:
		return false
	var xf := spr.get_global_transform()
	if not (xf * spr.get_rect()).intersects(caja):
		return false
	var img := _imagen(spr)
	var base := spr.region_rect.position if spr.region_enabled else Vector2.ZERO
	var inv := xf.affine_inverse()
	for fx in [0.15, 0.5, 0.85]:
		for fy in [0.1, 0.35, 0.6, 0.85]:
			var p: Vector2 = inv * (caja.position + caja.size * Vector2(fx, fy)) - spr.offset
			var r := spr.get_rect().size
			if p.x < 0 or p.y < 0 or p.x >= r.x or p.y >= r.y:
				continue
			var px := Vector2i(base + p)
			if img.get_pixelv(px).a > 0.5:
				return true
	return false

func _imagen(spr: Sprite2D) -> Image:
	var tex := spr.texture
	if not _imagenes.has(tex):
		_imagenes[tex] = tex.get_image()
	return _imagenes[tex]
