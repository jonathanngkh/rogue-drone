extends Node

@export var ip_address := "127.0.0.1"
#@export var ip_address := "192.168.1.117"
@export var default_port := 7777

@onready var start_server_button: Button = $StartServerButton
@onready var connect_to_server_button: Button = $ConnectToServerButton
@onready var terminate_networking_button: Button = $TerminateNetworkingButton
@onready var username_form: LineEdit = $UsernameForm
@onready var start_game_button: Button = $StartGameButton
@onready var username_label: Label = $UsernameLabel
@onready var connected_label: Label = $ConnectedLabel
@onready var server_started_label: Label = $ServerStartedLabel


func _ready():
	start_server_button.button_up.connect(func() -> void:
		start_server()
		# add self to Players_Dict
		Send_Player_Info(username_form.text, multiplayer.get_unique_id()))
	connect_to_server_button.button_up.connect(func() -> void: connect_to_server(ip_address, default_port))
	start_game_button.button_up.connect(func() -> void: Start_Game.rpc())
	terminate_networking_button.button_up.connect(func() -> void: terminate_networking())
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(func() -> void:
		Send_Player_Info.rpc_id(1, username_form.text, multiplayer.get_unique_id())
		connected_label.visible = true
		print('Signal: Client successfully connected to server')) # Called only from clients
	multiplayer.connection_failed.connect(func() -> void: print('Signal: Client failed to connect to server'))
	if "--server" in OS.get_cmdline_args():
		start_server()


# Server setup
func start_server(port: int = 7777):
	print("Attempting to start server...")
	var peer = ENetMultiplayerPeer.new()
	if peer.create_server(port, 2) != OK:
		print("Failed to create server")
		return
	multiplayer.multiplayer_peer = peer
	print("Server started on port %d" % port)
	server_started_label.visible = true


# Client setup
func connect_to_server(ip: String, port: int = 7777):
	print("Attempting to connect to server at %s:%d" % [ip, port])
	if !multiplayer.multiplayer_peer:
		print("No server found. Unable to connect.")
		return
		
	var peer = ENetMultiplayerPeer.new()
	if peer.create_client(ip, port) != OK:
		print("Failed to connect to server")
		return
	multiplayer.multiplayer_peer = peer
	print("Connected to server at %s:%d" % [ip, port])


# Terminate networking
func terminate_networking() -> void:
	multiplayer.multiplayer_peer = null
	print("Networking terminated")


# Signals for connections. Called on Server and Client
func _on_peer_connected(id: int):
	pass
	#print("Player connected with ID: %d (Is server: %s)" % [multiplayer.get_unique_id(), multiplayer.is_server()])
	#print("Player connected with ID: %d (Is server: %s)" % [id, multiplayer.is_server()])
	#connected_peers.append(id)
	#print("Connected peers: %s" % str(connected_peers))


func _on_peer_disconnected(id: int):
	pass
	#print("Player disconnected with ID: %d (Is server: %s)" % [multiplayer.get_unique_id(), multiplayer.is_server()])
	#print("Player disconnected with ID: %d (Is server: %s)" % [id, multiplayer.is_server()])
	#connected_peers.erase(id)
	#print("Connected peers: %s" % str(connected_peers))


@rpc("any_peer", "call_local")
func Start_Game() -> void:
	var scene = load("res://main_networking.tscn").instantiate()
	get_tree().root.add_child(scene)
	self.visible = false


@rpc("any_peer")
func Send_Player_Info(username, id) -> void:
	if not GameManager.Players_Dict.has(id):
		GameManager.Players_Dict[id] = {
			"username": username,
			"id": id
		}
		
	# pass the info on to all client-players
	if multiplayer.is_server():
		print(GameManager.Players_Dict)
		for player_id in GameManager.Players_Dict:
			Send_Player_Info.rpc(GameManager.Players_Dict[player_id].username, player_id)
