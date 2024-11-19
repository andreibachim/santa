extends Node2D
class_name Game

static var packed_scene := preload("res://screens/game/Game.tscn")

@onready var player_list := $Players
@onready var player_spawner := $PlayerSpawner

@onready var ui_overlay := $UI/Overlay

var player_packed_scene := preload("res://player/Player.tscn")

var random_seed: int
var player_name: String
var color: Color

#SERVER VARIABLES
var loaded_players := []

static func create(_random_seed: int) -> Game:
	var game: Game = packed_scene.instantiate()
	game.random_seed = _random_seed
	return game

static func create_for_client(_random_seed: int, _player_name: String, _color: Color) -> Game:
	var game: Game = Game.create(_random_seed)
	game.player_name = _player_name
	game.color = _color
	return game

func generate() -> void:
	pass

func _ready() -> void:
	player_spawner.set_spawn_function(_spawn_player)
	if !multiplayer.is_server():
		client_game_ready.rpc_id(1, player_name, color)

#RUNS ON THE SERVER
@rpc("any_peer", "call_remote", "reliable")
func client_game_ready(_player_name: String, _color: Color) -> void:
	loaded_players.append({
		"peer_id": multiplayer.get_remote_sender_id(),
		"color": _color,
		"player_name": _player_name
	})
	if loaded_players.size() == multiplayer.get_peers().size():
		for loaded_player in loaded_players:
			player_spawner.spawn(loaded_player)

#RUNS ON CLIENTS
func _spawn_player(data) -> Player:
	get_tree().create_tween().tween_property(ui_overlay, "modulate:a", 0, 0.2)
	var player: Player = player_packed_scene.instantiate()
	player.set_name(str(data.peer_id))
	player.set_multiplayer_authority(data.peer_id)
	player.set_player_name(data.player_name)
	player.set_color(data.color)
	return player
