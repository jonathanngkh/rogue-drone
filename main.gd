extends Node

@export var player_scene : PackedScene = preload("res://Drone/drone.tscn")
#@export var player_scene_2 : PackedScene = preload("res://Drone/drone_p2.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if name == "MainNetworking":
		var index = 0
		for player in GameManager.Players_Dict:
			var current_player
			current_player = player_scene.instantiate()
			current_player.name = str(GameManager.Players_Dict[player].id)
			#if index == 0:
				#current_player = player_scene.instantiate()
			#elif index == 1:
				#current_player = player_scene_2.instantiate()
			add_child(current_player)
			for spawn_location in get_tree().get_nodes_in_group("spawn_point"):
				if spawn_location.name == str(index):
					current_player.global_position = spawn_location.global_position
			index += 1


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
