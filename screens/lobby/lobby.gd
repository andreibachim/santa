extends Control
class_name Lobby

@onready var player_list := $UI/VBoxContainer/PlayerList
@onready var start_button := $UI/VBoxContainer/HBoxContainer/Start
@onready var lobby_id_value := $UI/VBoxContainer/LobbyIdContainer/HBoxContainer/LobbyIdValue
@onready var overlay := $UI/Overlay
@onready var lobby_ui := $UI

const lobby_player_packed_scene := preload("res://ui/components/LobbyPlayer.tscn")
const min_players_count = 0
var colors = [Color.RED, 
				Color.GREEN, 
				Color.PURPLE, 
				Color.BLUE, 
				Color.ORANGE, 
				Color.BROWN]

func _ready() -> void:
	multiplayer.peer_disconnected.connect(remove_player_from_ui)
	multiplayer.server_disconnected.connect(func():
		queue_free()
		multiplayer.multiplayer_peer = null
		Nav.load_landing_screen()
	)

func set_id_label(lobby_id: int) -> void:
	lobby_id_value.text = str(lobby_id)

#RUNS ON THE SERVER
@rpc("any_peer", "call_remote", "reliable")
func create_player(player_name: String) -> void:
	var lobby_player_instance: LobbyPlayer = lobby_player_packed_scene.instantiate()
	lobby_player_instance.text = player_name
	lobby_player_instance.peer_id = multiplayer.get_remote_sender_id()
	var color = colors.pop_at(randi_range(0, colors.size() - 1))
	lobby_player_instance.set_color(color)
	player_list.add_child(lobby_player_instance, true)
	if player_list.get_child_count() > min_players_count:
		start_button.disabled = false

#RUNS ON PEERS
func remove_player_from_ui(id: int) -> void:
	if multiplayer.is_server():
		if lobby_ui != null:
			for lobby_player: LobbyPlayer in player_list.get_children():
				if lobby_player.peer_id == id:
					player_list.remove_child(lobby_player)
					lobby_player.queue_free()
					if player_list.get_child_count() == 0:
						queue_free()
					elif player_list.get_child_count() < 2:
						start_button.disabled = true
		elif get_node("Game") != null:
			pass

func _on_leave_button_up() -> void:
	player_left.rpc_id(1)

#RUNS ON THE SERVER
@rpc("any_peer", "call_remote", "reliable")
func player_left() -> void:
	remove_player_from_ui(multiplayer.get_remote_sender_id())
	multiplayer.disconnect_peer(multiplayer.get_remote_sender_id())

#RUNS ON THE CLIENT
func _on_start_button_up() -> void:
	start_button.disabled = true
	start_game.rpc_id(1)

#RUN ON THE SERVER
@rpc("any_peer", "call_remote", "reliable")
func start_game() -> void:
	start_button.disabled = true
	var tween = get_tree().create_tween()
	tween.tween_method(func(value: int): start_button.text = str(value), 5, 0, 5)
	var world_seed = randi_range(10_000_000, 99_999_999)
	var game: Game = Game.create(world_seed)
	game.generate()
	add_child(game)
	await tween.finished
	lobby_ui.queue_free()
	for player: LobbyPlayer in player_list.get_children():
		load_game_scene.rpc_id(player.peer_id, 
			game.random_seed,
			player.text,
			player.modulate)

#RUNS ON THE CLIENTS
@rpc("authority", "call_remote", "reliable")
func load_game_scene(world_seed: int, player_name: String, color: Color) -> void:
	var hide_tween = get_tree().create_tween()
	hide_tween.tween_property(overlay, "modulate:a", 1, 0.2)
	await hide_tween.finished
	var game: Game = Game.create_for_client(world_seed, player_name, color)
	game.generate()
	lobby_ui.queue_free()
	add_child(game)
