extends Control

@onready var name_line_edit := $CenterContainer/VBoxContainer/LineEdit
@onready var join_button := $CenterContainer/VBoxContainer/Join
@onready var create_button := $CenterContainer/VBoxContainer/Create
@onready var error_dialog := $CenterContainer/ErrorDialog
@onready var lobby_id_dialog := $CenterContainer/LobbyNameDialog
@onready var lobby_id_input := $CenterContainer/LobbyNameDialog/MarginContainer/LineEdit

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
		name_line_edit.grab_focus()
		lobby_id_dialog.register_text_enter(lobby_id_input)

func _on_line_edit_text_changed(new_text: String) -> void:
	if new_text.length() > 2:
		join_button.disabled = false
		create_button.disabled = false
	else:
		join_button.disabled = true
		create_button.disabled = true

func _on_join_button_up() -> void:
	show_lobby_id_dialog();

func _on_create_button_up() -> void:
	pass
	
func create_client_peer() -> void:
	var client_peer = ENetMultiplayerPeer.new();
	var result = client_peer.create_client(SERVER_IP, -1)
	if result == OK: 
		multiplayer.multiplayer_peer = client_peer
	else:
		error_dialog.dialog_text = "The server is not available."
		error_dialog.popup_centered_clamped(Vector2(180, 60))

func show_lobby_id_dialog() -> void:
	join_button.release_focus()
	lobby_id_dialog.popup_centered()
	lobby_id_input.grab_focus()

func _on_lobby_name_dialog_confirmed() -> void:
	create_client_peer()
