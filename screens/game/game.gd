extends Node2D
class_name Game

static var packed_scene := preload("res://screens/game/Game.tscn")

@onready var player_list := $Players
@onready var player_spawner := $Players/PlayerSpawner

var player_packed_scene := preload("res://player/Player.tscn")
var random_seed: int
var user_color: Color

static func create(_random_seed: int, color: Color) -> Game:
	var game: Game = packed_scene.instantiate()
	game.random_seed = _random_seed
	game.user_color = color
	return game

func generate() -> void:
	pass

func _ready() -> void:
	var val = "Server" if multiplayer.is_server() else "Client"
	print(val + " is ready!")
	player_spawner.set_spawn_function(_spawn_player)
	if !multiplayer.is_server():
		print("This should be printed first " + str(multiplayer.get_unique_id()))
		game_ready.rpc_id(1, user_color)

#RUNS ON THE SERVER
@rpc("any_peer", "call_remote", "reliable")
func game_ready(color: Color) -> void:
	print("And this should be printed second " + str(multiplayer.get_remote_sender_id()))
	player_spawner.spawn({
		"color": color,
		"peer_id": multiplayer.get_remote_sender_id(),
		"name": "Pulica Frânaru"
	})

#RUNS ON CLIENTS
func _spawn_player(data) -> Player:
	set_multiplayer_authority(data.peer_id)
	var player: Player = player_packed_scene.instantiate()
	return player
