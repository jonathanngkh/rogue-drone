extends CharacterBody3D

const SPEED = 15.0
const JUMP_VELOCITY = 10
@onready var drone_animation_player: AnimationPlayer = $"Pivot/drone edited origins/DroneAnimationPlayer"


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_pressed("throttle_forward"):
		velocity.y = JUMP_VELOCITY
		drone_animation_player.play("throttle_forward")
		drone_animation_player.speed_scale = 10

	if Input.is_action_pressed("throttle_back") and not is_on_floor():
		velocity.y = -JUMP_VELOCITY
		drone_animation_player.play_backwards("throttle_forward")

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	#var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	#var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	#if direction:
		#velocity.x = direction.x * SPEED
		#velocity.z = direction.z * SPEED
	#else:
		#velocity.x = move_toward(velocity.x, 0, SPEED)
		#velocity.z = move_toward(velocity.z, 0, SPEED)
#
	move_and_slide()
