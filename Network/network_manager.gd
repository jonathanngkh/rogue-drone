extends Node

var connected_peers = []
@export var ip_address := "127.0.0.1"
#@export var ip_address := "192.168.1.117"
@export var default_port := 7777

@onready var start_server_button: Button = $StartServerButton
@onready var connect_to_server_button: Button = $ConnectToServerButton
@onready var terminate_networking_button: Button = $TerminateNetworkingButton

func _ready():
	start_server_button.button_up.connect(func() -> void: start_server())
	connect_to_server_button.button_up.connect(func() -> void: connect_to_server(ip_address, default_port))
	terminate_networking_button.button_up.connect(func() -> void: terminate_networking())
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(func() -> void: print('Signal: Client successfully connected to server'))
	multiplayer.connection_failed.connect(func() -> void: print('Signal: Client failed to connect to server'))


# Server setup
func start_server(port: int = 7777):
	print("Attempting to start server...")
	var peer = ENetMultiplayerPeer.new()
	if peer.create_server(port, 2) != OK:
		print("Failed to create server")
		return
	multiplayer.multiplayer_peer = peer
	print("Server started on port %d" % port)


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


# Signals for connections
func _on_peer_connected(id: int):
	print("Player connected with ID: %d (Is server: %s)" % [multiplayer.get_unique_id(), multiplayer.is_server()])
	connected_peers.append(id)
	print("Connected peers: %s" % str(connected_peers))


func _on_peer_disconnected(id: int):
	print("Player disconnected with ID: %d (Is server: %s)" % [multiplayer.get_unique_id(), multiplayer.is_server()])
	connected_peers.erase(id)
	print("Connected peers: %s" % str(connected_peers))
