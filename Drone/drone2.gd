extends CharacterBody3D

@onready var drone_animation_player: AnimationPlayer = $"Pivot/drone edited origins/DroneAnimationPlayer"
@onready var bullet_scene: PackedScene = preload("res://Bullet/bullet.tscn") # Bullet scene
@onready var ray_cast: RayCast3D = $Node3D/Camera3D/RayCast3D
@onready var fpv_camera: Camera3D = $Node3D/Camera3D
@onready var laser: MeshInstance3D = $Scaler/Laser
@onready var engine_sound: AudioStreamPlayer3D = $EngineSound
@onready var hit_marker_sound: AudioStreamPlayer3D = $HitMarkerSound


@export var zoom_sensitivity_multiplier: float = 0.5 # Reduce sensitivity to 50% while zoomed in
@export var bullet_speed = 100.0 # Bullet speed
@export var max_thrust = 60.0 # Maximum upward force (throttle)
@export var max_yaw_speed = 6.0 # Maximum rotational speed for yaw
@export var max_pitch_speed = 5.0 # Maximum rotational speed for pitch
@export var max_roll_speed = 5.0 # Maximum rotational speed for roll
@export var friction_coefficient = 10 # Adjust this value to tune the friction intensity
@export var drag_coefficient = 0.1 # Adjust this value to tune drag intensity
@export var angular_drag_coefficient = 0.1 # Adjust this to tune angular drag intensity
@export var default_fov: float = 90.0  # Normal field of view
@export var zoom_fov: float = 30.0     # Zoomed-in field of view
@export var zoom_speed: float = 10.0   # How fast the zoom transitions
# Export pitch range for tuning
@export var min_pitch = 1.0  # Pitch at zero throttle
@export var max_pitch = 1.7  # Pitch at full throttle
@export var min_volume = -15  # Volume (dB) at zero throttle
@export var max_volume = 0  # Volume (dB) at full throttle

# Variables to track angular velocities
var pitch_velocity: float = 0.0
var yaw_velocity: float = 0.0
var roll_velocity: float = 0.0

var is_ADS : bool = false


func _physics_process(delta: float) -> void:
	# Handle ADS
	if Input.is_action_pressed("aim_down_sights"): # Check if L1 is held
		is_ADS = true
		fpv_camera.fov = lerp(fpv_camera.fov, zoom_fov, zoom_speed * delta)
	else:
		fpv_camera.fov = lerp(fpv_camera.fov, default_fov, zoom_speed * delta)
	
	if Input.is_action_just_pressed("aim_down_sights"):
		max_pitch_speed *= zoom_sensitivity_multiplier
		max_roll_speed *= zoom_sensitivity_multiplier
		max_yaw_speed *= zoom_sensitivity_multiplier
	if Input.is_action_just_released("aim_down_sights"):
		is_ADS = false
		max_pitch_speed *= 1/zoom_sensitivity_multiplier
		max_roll_speed *= 1/zoom_sensitivity_multiplier
		max_yaw_speed *= 1/zoom_sensitivity_multiplier

	# Handle shooting with R1 button (gamepad button)
	if Input.is_action_pressed("shoot"):
		#shoot_bullet()
		shoot_laser()
		laser.get_active_material(0).albedo_color.a = 1.0

	if Input.is_action_just_released("shoot"):
		var laser_material = laser.get_active_material(0)
		var tween = create_tween()
		tween.tween_property(laser_material, "albedo_color:a", 0.0, 0.2).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		
		#laser.visible = false

	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		apply_friction(delta)
		reset_orientation_to_neutral() # can use this for ez hover
	
	# Get throttle input (left stick Y-axis)
	var throttle_input = Input.get_action_strength("throttle_forward")
	
	# Apply thrust
	apply_thrust(throttle_input, delta)
	
	
	# Apply angular drag to reduce angular velocities
	apply_angular_drag(delta)
	
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
	
	# Adjust engine sound based on throttle input
	update_engine_sound(throttle_input, yaw_input, pitch_input, roll_input)
	

	# Play animation
	drone_animation_player.play("throttle_forward")
	drone_animation_player.speed_scale = 2 + throttle_input * 3
	# add yaw,pitch,roll animations also

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
	var smooth_quat = current_quaternion.slerp(target_quaternion, 0.2) # Adjust 0.1 for smoothness

	# Apply the interpolated rotation
	transform.basis = Basis(smooth_quat)

func shoot_bullet() -> void:
	# Instantiate the bullet
	var bullet = bullet_scene.instantiate()

	# Add the bullet to the scene and apply a force to shoot it forward
	get_parent().add_child(bullet)
	# Set the bullet's initial position and rotation to match the drone's current position and facing direction
	bullet.global_transform.origin = transform.origin - 3*transform.basis.z  # Position in front of the drone
	bullet.rotation_degrees = transform.basis.get_euler() # Match the drone's rotation
	bullet.apply_impulse(-transform.basis.z * bullet_speed + velocity, Vector3.ZERO)


func shoot_laser() -> void:
	laser.visible = true
	
	if ray_cast.is_colliding():
		if ray_cast.get_collider().is_in_group("bullseye"):
			print('laser hit')
			ray_cast.get_collider().hit_by_bullet()
			hit_marker_sound.play()


func update_engine_sound(throttle_input: float, yaw_input: float, pitch_input: float, roll_input: float) -> void:
	# Calculate pitch and volume based on throttle
	pitch_input = abs(pitch_input)
	yaw_input = abs(yaw_input)
	roll_input = abs(roll_input)
	var pitch = lerp(min_pitch, max_pitch, throttle_input * 1.2+(yaw_input/2)+(pitch_input/2)+(roll_input/2))
	var volume = lerp(min_volume, max_volume, throttle_input*1.2+(yaw_input/2)+(pitch_input/2)+(roll_input/2))

	# Apply pitch and volume to the engine sound
	engine_sound.pitch_scale = pitch
	engine_sound.volume_db = volume

	# Start the engine sound if not already playing
	if not engine_sound.playing:
		engine_sound.play()
