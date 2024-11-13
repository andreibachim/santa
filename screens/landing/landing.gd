extends Control

@onready var name_line_edit := $CenterContainer/VBoxContainer/LineEdit
@onready var join_button := $CenterContainer/VBoxContainer/Join
@onready var create_button := $CenterContainer/VBoxContainer/Create
@onready var error_dialog := $CenterContainer/ErrorDialog
@onready var lobby_id_dialog := $CenterContainer/LobbyNameDialog
@onready var lobby_id_input := $CenterContainer/LobbyNameDialog/MarginContainer/LineEdit
@onready var no_server_warning := $NoServerWarning

var lobby_packed_scene := preload("res://screens/lobby/Lobby.tscn")

var server_available: bool = false

const SERVER_IP: String = "localhost"
const LOBBY_PORT: int = 7000

func _ready() -> void:
	if OS.get_cmdline_args().has("server"):
		$CenterContainer.queue_free()
		var server_peer = ENetMultiplayerPeer.new()
		server_peer.create_server(LOBBY_PORT)
		multiplayer.multiplayer_peer = server_peer
		return
	else:
		var client_peer = ENetMultiplayerPeer.new()
		var result = client_peer.create_client(SERVER_IP, LOBBY_PORT)
		if result == OK: 
			multiplayer.multiplayer_peer = client_peer
			multiplayer.server_disconnected.connect(func(): 
				server_available = false
				no_server_warning.visible = true
				join_button.disabled = true
				create_button.disabled = true
			)
			server_available = true
		else:
			server_available = false
			no_server_warning.visible = true

		name_line_edit.grab_focus()
		lobby_id_dialog.register_text_enter(lobby_id_input)

func _on_line_edit_text_changed(new_text: String) -> void:
	if new_text.length() > 2:
		join_button.disabled = false || !server_available
		create_button.disabled = false || !server_available
	else:
		join_button.disabled = true || !server_available
		create_button.disabled = true || !server_available

func _on_join_button_up() -> void:
	show_lobby_id_dialog()
	
func _on_create_button_up() -> void:
	create_button.disabled = true
	join_button.disabled = true
	name_line_edit.editable = false
	create_lobby.rpc_id(1)
	
func show_lobby_id_dialog() -> void:
	join_button.release_focus()
	lobby_id_dialog.popup_centered()
	lobby_id_input.grab_focus()

func _on_lobby_name_dialog_confirmed() -> void:
	var lobby_id = int(lobby_id_input.text)
	#TODO validate lobby id
	load_lobby(lobby_id)

@rpc("authority", "call_remote", "reliable")
func show_lobby_create_error() -> void:
	create_button.disabled = false || !server_available
	join_button.disabled = false || !server_available
	name_line_edit.editable = true
	error_dialog.dialog_text = "Could not create lobby"
	error_dialog.popup_centered()

@rpc("any_peer", "call_remote", "reliable")
func create_lobby():
	#Generate random lobby port
	var lobby_id = randi_range(65000, 65100)
	var path = str(get_tree().current_scene.get_path()) + "/" + str(lobby_id)
	#Create the lobby MP
	var mp = SceneMultiplayer.new()
	#Add the lobby MP to the tree
	get_tree().set_multiplayer(mp, path)
	#Create the peer
	var peer = ENetMultiplayerPeer.new()
	if peer.create_server(lobby_id, 6) == OK:
		mp.multiplayer_peer = peer
		var lobby_instance: Lobby = lobby_packed_scene.instantiate()
		lobby_instance.name = str(lobby_id)
		get_tree().current_scene.add_child(lobby_instance)
		lobby_instance.set_id_label(lobby_id)

		load_lobby.rpc_id(multiplayer.get_remote_sender_id(), lobby_id)
		#TODO Start timer to remove empty lobbies after 1 min
	else:
		get_tree().set_multiplayer(null, path)
		print(multiplayer.get_remote_sender_id())
		show_lobby_create_error.rpc_id(multiplayer.get_remote_sender_id())

@rpc("authority", "call_remote", "reliable")
func load_lobby(lobby_id: int) -> void:
	var path = str(get_tree().current_scene.get_path()) + "/" + str(lobby_id)
	var mp = SceneMultiplayer.new();
	get_tree().set_multiplayer(mp, path)
	var peer = ENetMultiplayerPeer.new()
	if peer.create_client(SERVER_IP, lobby_id) == OK:
		mp.multiplayer_peer = peer
		var lobby_instance: Lobby = lobby_packed_scene.instantiate()
		lobby_instance.name = str(lobby_id)
		mp.connected_to_server.connect(func(): 
			get_tree().current_scene.add_child(lobby_instance)
			lobby_instance.set_id_label(lobby_id)
			lobby_instance.create_player.rpc_id(1, name_line_edit.text)
			multiplayer.multiplayer_peer = null
			queue_free()
		)
		mp.connection_failed.connect(func():
			show_lobby_create_error()
		)
	else:
		show_lobby_create_error()
