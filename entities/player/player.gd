class_name Player
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


@onready var camera: PlayerCamera = $PlayerCamera

@onready var sprite: Node2D = $Sprite
@onready var arm: Node2D = $Sprite/Arm
@onready var held: Node2D = $Sprite/Arm/Held

@onready var health: HealthComponent = $HealthComponent


@onready var coyote_time_left: float = coyote_time

## global position
var look_target: Vector2 = Vector2.ZERO
var aim_vector: Vector2 = Vector2.RIGHT
var aim_strength: float = 0.0 ## 0 = mouse, 1 = controller stick/aim keys
var jump_count: int = 0


enum AimMode {
	MOUSE,
	STICK
}

var aim_mode: AimMode = AimMode.MOUSE

const STICK_DEADZONE := 0.2
const SWITCH_THRESHOLD := 0.6


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

#region Process Functions

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

	var direction := Input.get_axis(&"move_left", &"move_right")
	if direction:
		velocity.x = move_toward(velocity.x, direction * move_speed, accel * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, accel * 1.5 * delta)

	$Reticle.position = to_local(look_target)

	move_and_slide()

func _process(delta: float) -> void:
	look_target = get_global_mouse_position()

	$Reticle.scale = Vector2.ONE * (2.0 + sin(float((Time.get_ticks_msec()) / 1000.0) * 5.0)) 
	$Reticle/ColorRect.rotation_degrees += RETICLE_ROTATION_SPEED * delta
	$Reticle/ColorRect2.rotation_degrees -= RETICLE_ROTATION_SPEED * delta

	camera.target = look_target
	process_targeting(delta)


func update_aim_mode() -> void:
	var stick_input := Input.get_vector(
		&"aim_left", &"aim_right",
		&"aim_up", &"aim_down"
	)
	var mouse_dir := Input.get_last_mouse_velocity()

	var stick_strength := stick_input.length()

	match aim_mode:
		AimMode.MOUSE:
			if stick_strength > SWITCH_THRESHOLD:
				aim_mode = AimMode.STICK

		AimMode.STICK:
			if stick_strength < STICK_DEADZONE:
				# only switch back if mouse is clearly intentional
				if mouse_dir.length() > 10.0:
					aim_mode = AimMode.MOUSE


func process_targeting(delta: float) -> void:
	var stick_input := Input.get_vector(
		&"aim_left", &"aim_right",
		&"aim_up", &"aim_down"
	)

	if stick_input.length() > 0.1:
		aim_vector = stick_input.normalized()
		aim_strength = 1.0
	else:
		aim_strength = 0.0

	var stick_target := global_position + aim_vector * 300.0
	var current_look_target := look_target.lerp(stick_target, aim_strength)

	var look_dir := current_look_target - global_position

	var facing_left := look_dir.x < 0
	sprite.scale.x = lerpf(
		sprite.scale.x,
		-1 if facing_left else 1,
		10.0 * delta
	)

	var arm_dir := current_look_target - arm.global_position

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

#endregion

#region Singal Recievers

func _on_hurt(_amount: int) -> void:
	camera.hitstop(0.2, 0.1)
	camera.shake(5.0, 1.0)
	

func _on_healed(_amount: int) -> void:
	pass # Replace with function body.

#endregion