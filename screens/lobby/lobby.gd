extends Control
class_name Lobby

@onready var player_list := $VBoxContainer/PlayerList
@onready var start_button := $VBoxContainer/HBoxContainer/Start
@onready var lobby_id_value := $VBoxContainer/LobbyIdContainer/HBoxContainer/LobbyIdValue

const lobby_player_packed_scene := preload("res://ui/components/LobbyPlayer.tscn")

func _ready() -> void:
	multiplayer.peer_disconnected.connect(remove_player_from_ui)
	multiplayer.server_disconnected.connect(func():
		queue_free()
		multiplayer.multiplayer_peer = null
		Nav.load_landing_screen()
	)

func set_id_label(lobby_id: int) -> void:
	lobby_id_value.text = str(lobby_id)

@rpc("any_peer", "call_remote", "reliable")
func create_player(player_name: String) -> void:
	var lobby_player_instance: LobbyPlayer = lobby_player_packed_scene.instantiate()
	lobby_player_instance.text = player_name
	lobby_player_instance.peer_id = multiplayer.get_remote_sender_id()
	player_list.add_child(lobby_player_instance, true)
	if player_list.get_child_count() > 1:
		start_button.disabled = false

func remove_player_from_ui(id: int) -> void:
	if multiplayer.is_server():
		for lobby_player: LobbyPlayer in player_list.get_children():
			if lobby_player.peer_id == id:
				player_list.remove_child(lobby_player)
				lobby_player.queue_free()
				if player_list.get_child_count() == 0:
					queue_free()
				elif player_list.get_child_count() < 2:
					start_button.disabled = true

func _on_leave_button_up() -> void:
	player_left.rpc_id(1)
	
@rpc("any_peer", "call_remote", "reliable")
func player_left() -> void:
	remove_player_from_ui(multiplayer.get_remote_sender_id())
	multiplayer.disconnect_peer(multiplayer.get_remote_sender_id())
