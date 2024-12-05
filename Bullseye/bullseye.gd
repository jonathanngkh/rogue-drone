extends CharacterBody3D
@export var glow_time = 0.5

@onready var green_indicator: MeshInstance3D = $GreenIndicator
@onready var player: Node3D
# Set this in the inspector to set the color to change to

func _ready() -> void:
	# Add the target to a group called "bullseye" to detect collisions
	add_to_group("bullseye")
	#mouse_entered.connect(func() -> void: print('hit'))
	player = get_tree().get_first_node_in_group('player')


func _process(_delta: float) -> void:
	# Get the position of the player
	var player_position = player.global_transform.origin
	
	# Make the bullseye face the player by setting its look_at
	look_at(player_position)
	
	
	
# Called when the bullet collides with the target
func hit_by_bullet() -> void:
	# Change the color of the bullseye to indicate a hit
	green_indicator.visible = true
	set_timer()

func set_timer() -> void:
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = glow_time
	timer.one_shot = true
	timer.timeout.connect(_on_timeout)
	timer.start()

func _on_timeout() -> void:
	green_indicator.visible = false
