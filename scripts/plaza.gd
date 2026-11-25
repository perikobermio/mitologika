extends "res://scripts/escena.gd"
## Plaza de Goiko: además de lo común, cada partida una farola al azar falla.


func _init() -> void:
	intensidad_sombras = 0.45   # farolas: sombra más tenue que la de las velas


func _ready() -> void:
	super._ready()
	var luces := []
	for n in $Mundo.get_children():
		if n.name.begins_with("Farola") and n.has_node("Luz"):
			luces.append(n.get_node("Luz"))
	if not luces.is_empty():
		luces.pick_random().set_inestable(true)
