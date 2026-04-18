class_name Player
extends CharacterBody2D


const SWITCH_THRESHOLD := 0.6
const MOUSE_DEADZONE := 5.0
const STICK_DEADZONE := 0.2
const STICK_AIM_DISTANCE := 1000.0
const STICK_AIM_LAG := 20.0


enum AimMode {
	MOUSE,
	STICK,
	NONE,
}


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

@onready var aim_center: Marker2D = $AimCenter

@onready var health: HealthComponent = $HealthComponent


@onready var coyote_time_left: float = coyote_time


var aim_mode: AimMode = AimMode.MOUSE
## global position
var aim_target: Vector2 = Vector2.ZERO
var last_valid_aim_vector: Vector2 = Vector2.ZERO
var aim_vector: Vector2 = Vector2.RIGHT
var jump_count: int = 0


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

	$Reticle.position = to_local(aim_target)

	move_and_slide()


func _process(delta: float) -> void:

	$Reticle.visible = aim_mode != AimMode.NONE
	$Reticle.scale = Vector2.ONE * (2.0 + sin(float((Time.get_ticks_msec()) / 1000.0) * 5.0))

	update_aim_target(delta)
	camera.target = aim_target
	process_targeting(delta)


func update_aim_target(delta) -> void:
	var stick_input := Input.get_vector(
		&"aim_left", &"aim_right",
		&"aim_up", &"aim_down"
	)
	var stick_strength := stick_input.length()
	var mouse_strength := Input.get_last_mouse_velocity().length()

	match aim_mode:
		AimMode.MOUSE:
			if stick_strength > SWITCH_THRESHOLD:
				aim_mode = AimMode.STICK
				return
			aim_target = get_global_mouse_position()
			last_valid_aim_vector = aim_center.global_position.direction_to(aim_target)
		AimMode.STICK:
			if stick_strength < STICK_DEADZONE and mouse_strength > MOUSE_DEADZONE:
				aim_mode = AimMode.MOUSE
				return
			var stick_target := aim_center.global_position + stick_input.normalized() * STICK_AIM_DISTANCE * lerpf(STICK_DEADZONE, 1.0, stick_strength)
			if stick_strength > STICK_DEADZONE:
				aim_target = aim_target.lerp(stick_target, STICK_AIM_LAG * delta)
				last_valid_aim_vector = stick_input.normalized()
			else:
				aim_mode = AimMode.NONE
		AimMode.NONE:
			if stick_strength > STICK_DEADZONE:
				aim_mode = AimMode.STICK
				return
			if mouse_strength > MOUSE_DEADZONE:
				aim_mode = AimMode.MOUSE
				return
			aim_target = aim_center.global_position + (last_valid_aim_vector * STICK_AIM_DISTANCE * STICK_DEADZONE)

	aim_vector = (aim_target - aim_center.global_position).normalized()


func process_targeting(delta: float) -> void:
	var facing_left := aim_vector.x < 0
	sprite.scale.x = lerpf(
		sprite.scale.x,
		-1 if facing_left else 1,
		10.0 * delta
	)

	var arm_dir := aim_target - arm.global_position

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