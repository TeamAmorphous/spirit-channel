extends CharacterBody2D


const RETICLE_ROTATION_SPEED: float = 180.0


@export_category("Physics")

@export var speed: float = 1200.0
@export var accel: float = 1500.0
@export var jump_velocity: float = 800.0
@export var sensitivity: float = 0.2
@export var coyote_time: float = 0.25 ## seconds
@export var max_jumps: int = 1

@export_category("Visual")
@export var arm_min_angle: float = -60
@export var arm_max_angle: float = 75

@export_group("Camera", "camera_")

@export var camera_max_look_ahead := 400.0
@export var camera_deadzone_radius := 100.0

@export var camera_follow_speed := 10.0     # toward mouse
@export var camera_return_speed := 4.0      # back to center
@export var camera_lag_strength := 8.0      # camera lag

var current_camera_offset := Vector2.ZERO

@onready var camera: Camera2D = $Camera2D

@onready var sprite: Node2D = $Sprite
@onready var arm: Node2D = $Sprite/Arm
@onready var held: Node2D = $Sprite/Arm/Held


var time: float = 0.0
## local to player
var look_target: Vector2 = Vector2.ZERO
var jump_count: int = 0
@onready var coyote_time_left: float = coyote_time

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)


func _physics_process(delta: float) -> void:
	var move_speed: float = speed  

	if not is_on_floor():
		velocity += get_gravity() * delta
		if coyote_time_left > 0:
			coyote_time_left = maxf(coyote_time_left - delta, 0)
	else: # is_on_floor()
		coyote_time_left = coyote_time
		jump_count = 0
	
	if Input.is_action_just_pressed(&"jump"):
		if (coyote_time_left > 0 and jump_count == 0) or (jump_count > 0 and jump_count < max_jumps):
			velocity.y = -jump_velocity
			jump_count += 1
			coyote_time_left = 0


	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis(&"move_left", &"move_right")
	if direction:
		velocity.x = move_toward(velocity.x, direction * move_speed, accel * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, accel * 1.5 * delta)

	move_and_slide()

func _process(delta: float) -> void:
	look_target = get_global_mouse_position()

	time += delta
	$Reticle.scale = Vector2.ONE * (2.0 + sin(time * 5.0)) 
	$Reticle.position = to_local(look_target)
	$Reticle/ColorRect.rotation_degrees += RETICLE_ROTATION_SPEED * delta
	$Reticle/ColorRect2.rotation_degrees -= RETICLE_ROTATION_SPEED * delta

	process_sprite_look(delta)
	process_camera(delta)


func process_sprite_look(delta: float) -> void:
	var look_dir := look_target - global_position

	var facing_left := look_dir.x < 0
	sprite.scale.x = lerpf(
		sprite.scale.x,
		-1 if facing_left else 1,
		10.0 * delta
	)

	var arm_dir := look_target - arm.global_position

	if facing_left:
		arm_dir.x *= -1
	
	var arm_angle = clampf(
		arm_dir.angle(),
		deg_to_rad(arm_min_angle),
		deg_to_rad(arm_max_angle)
	)

	if facing_left:
		arm_angle = PI - arm_angle
	
	arm.global_rotation = lerp_angle(
		arm.global_rotation,
		arm_angle,
		15.0 * delta
	)

func process_camera(delta: float) -> void:
	var to_look_pos := look_target - global_position
	var distance := to_look_pos.length()

	if distance < camera_deadzone_radius:
		to_look_pos = Vector2.ZERO
		distance = 0.0

	var strength := clampf((distance - camera_deadzone_radius) / 800.0, 0.0, 1.0)
	strength *= strength # << quadratic easing
	
	var target_offset := Vector2.ZERO
	if distance > 0:
		target_offset = to_look_pos.normalized() * camera_max_look_ahead * strength

	var camera_speed := camera_follow_speed if target_offset.length_squared() > current_camera_offset.length_squared() else camera_return_speed
	current_camera_offset = current_camera_offset.lerp(target_offset, camera_speed * delta)

	camera.offset = camera.offset.lerp(current_camera_offset, camera_lag_strength * delta)
