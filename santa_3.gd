extends Node

func _ready() -> void:
	var mp = SceneMultiplayer.new()
	get_tree().set_multiplayer(mp ,"/root/Landing")
	Nav.load_landing_screen()
