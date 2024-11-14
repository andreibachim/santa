extends Label
class_name LobbyPlayer

@export var peer_id: int

func set_color(color: Color) -> void:
	modulate = color
