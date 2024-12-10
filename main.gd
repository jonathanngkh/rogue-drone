extends Node

@export var ip_address := "127.0.0.1"
#@export var ip_address := "192.168.1.117"
@export var port := 7777

@onready var network_manager: Node = $NetworkManager
@onready var start_server_button: Button = $UI/StartServerButton
@onready var connect_to_server_button: Button = $UI/ConnectToServerButton
@onready var terminate_networking_button: Button = $UI/TerminateNetworkingButton


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	start_server_button.button_up.connect(func() -> void: network_manager.start_server())
	#connect_to_server_button.button_up.connect(func() -> void: network_manager.connect_to_server("192.168.1.117"))
	connect_to_server_button.button_up.connect(func() -> void: network_manager.connect_to_server(ip_address, port))
	terminate_networking_button.button_up.connect(func() -> void: network_manager.terminate_networking())


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
