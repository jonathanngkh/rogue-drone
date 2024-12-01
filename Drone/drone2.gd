extends CharacterBody3D

@onready var drone_animation_player: AnimationPlayer = $"Pivot/drone edited origins/DroneAnimationPlayer"

@export var max_thrust = 60.0 # Maximum upward force (throttle)
@export var drag_coefficient = 0.1 # Adjust this value to tune drag intensity
@export var angular_drag_coefficient = 0.1 # Adjust this to tune angular drag intensity
@export var max_yaw_speed = 6.0 # Maximum rotational speed for yaw
@export var max_pitch_speed = 3.0 # Maximum rotational speed for pitch
@export var max_roll_speed = 3.0 # Maximum rotational speed for roll
@export var friction_coefficient = 10 # Adjust this value to tune the friction intensity


# Add variables to track angular velocities
var pitch_velocity: float = 0.0
var yaw_velocity: float = 0.0
var roll_velocity: float = 0.0

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
		print("in air")
	else:
		apply_friction(delta)
		print("on floor")
		reset_orientation_to_neutral() # can use this for ez hover
		
	# Get throttle input (left stick Y-axis)
	var throttle_input = Input.get_action_strength("throttle_forward")
	
	# Apply angular drag to reduce angular velocities
	apply_angular_drag(delta)
	
	# Apply thrust
	apply_thrust(throttle_input, delta)
	
	# Get yaw input (left stick X-axis)
	var yaw_input = Input.get_action_strength("yaw_left") - Input.get_action_strength("yaw_right")
	
	# Apply yaw
	apply_yaw(yaw_input, delta)
	
	# Get roll input (right stick X-axis)
	var roll_input = Input.get_action_strength("roll_left") - Input.get_action_strength("roll_right")
	
	# Apply roll
	apply_roll(roll_input, delta)
	
		# Get pitch input (right stick Y-axis)
	var pitch_input = Input.get_action_strength("pitch_backward") - Input.get_action_strength("pitch_forward")
	
	# Apply pitch
	apply_pitch(pitch_input, delta)
	
	# Play animation
	drone_animation_player.play("throttle_forward")
	drone_animation_player.speed_scale = 2 + throttle_input * 3

	# Move using built-in velocity
	move_and_slide()


func apply_thrust(throttle_input: float, delta: float) -> void:
	# Get the thrust direction (normal to the drone's plane)
	var thrust_direction = transform.basis.y.normalized() # Local "up" direction relative to the drone

	# Scale the thrust direction by the input and maximum thrust
	var thrust_force = thrust_direction * throttle_input * max_thrust

	# Apply thrust directly to velocity, scaled by delta
	if throttle_input > 0:
		velocity += thrust_force * delta

	# Introduce drag to counter excessive acceleration
	apply_drag(delta)


func apply_drag(delta: float) -> void:
	# Drag reduces velocity proportionally to its current magnitude
	var drag_force = velocity * drag_coefficient * delta
	velocity -= drag_force


# Apply yaw rotation
func apply_yaw(yaw_input: float, delta: float) -> void:
	# Apply yaw rotation around the Y-axis (horizontal plane)
	yaw_velocity = yaw_input * max_yaw_speed * delta
	rotate_object_local(Vector3(0, 1, 0), yaw_velocity)

 # Apply pitch rotation and thrust
func apply_pitch(pitch_input: float, delta: float) -> void:
	# Apply pitch rotation around the drone's local X-axis
	pitch_velocity = pitch_input * max_pitch_speed * delta
	
	# Rotate the drone using its local X-axis
	rotate_object_local(Vector3(1, 0, 0), pitch_velocity)


func apply_roll(roll_input: float, delta: float) -> void:
	# Apply roll rotation around the drone's local Z-axis
	roll_velocity = roll_input * max_roll_speed * delta
	
	# Rotate the drone using its local Z-axis
	rotate_object_local(Vector3(0, 0, 1), roll_velocity)


# Apply angular drag function
func apply_angular_drag(delta: float) -> void:
	# Apply drag to each angular velocity component (pitch, yaw, roll)
	pitch_velocity -= pitch_velocity * angular_drag_coefficient * delta
	yaw_velocity -= yaw_velocity * angular_drag_coefficient * delta
	roll_velocity -= roll_velocity * angular_drag_coefficient * delta
	

# Apply friction function
func apply_friction(delta: float) -> void:
	# Apply friction to the x and z components of the velocity
	velocity.x -= velocity.x * friction_coefficient * delta
	velocity.z -= velocity.z * friction_coefficient * delta

#
#func reset_orientation_to_neutral() -> void:
	## Set the drone's pitch and roll to neutral (parallel to the ground)
	#var target_rotation = transform.basis.get_euler()
	#target_rotation.x = 0 # Set pitch to 0 (parallel to the ground)
	#target_rotation.z = 0 # Set roll to 0 (parallel to the ground)
#
	## Apply the new rotation (convert Euler back to Quaternion if needed)
	#transform.basis = Basis().from_euler(target_rotation)


func reset_orientation_to_neutral() -> void: # but 'smoothly'
	# Set the drone's pitch and roll to neutral (parallel to the ground)
	var target_rotation = transform.basis.get_euler()
	target_rotation.x = 0 # Set pitch to 0 (parallel to the ground)
	target_rotation.z = 0 # Set roll to 0 (parallel to the ground)

	# Create a quaternion from the target rotation (Euler angles)
	var target_quaternion = Quaternion.from_euler(target_rotation)

	# Interpolate from the current rotation to the target rotation
	var current_quaternion = transform.basis.get_rotation_quaternion()
	var smooth_quat = current_quaternion.slerp(target_quaternion, 0.5) # Adjust 0.1 for smoothness

	# Apply the interpolated rotation
	transform.basis = Basis(smooth_quat)
