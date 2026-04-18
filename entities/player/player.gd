class_name Player
extends CharacterBody2D


const SWITCH_THRESHOLD := 0.6
const MOUSE_DEADZONE := 5.0
const STICK_DEADZONE := 0.2
const STICK_AIM_DISTANCE := 1000.0
const STICK_AIM_LAG := 20.0




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
@export var pupils_min_y_offset: float = -9.0
@export var pupils_max_y_offset: float = 9.0


@onready var camera: PlayerCamera = $PlayerCamera

@onready var sprite: Node2D = $Sprite
@onready var arm: Node2D = $Sprite/Arm
@onready var body: AnimatedSprite2D = $Sprite/Body

@onready var tv: ColorRect = $Sprite/Body/TV
@onready var eyes: Sprite2D = $Sprite/Body/Eyes
@onready var pupils: Sprite2D = $Sprite/Body/Eyes/Pupils

@onready var health: HealthComponent = $HealthComponent
@onready var aim: AimController = $AimController


@onready var coyote_time_left: float = coyote_time

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

	$Reticle.position = to_local(aim.target)

	move_and_slide()


func _process(delta: float) -> void:
	$Reticle.visible = aim.mode != AimController.Mode.NONE
	$Reticle.scale = Vector2.ONE * (2.0 + sin(float((Time.get_ticks_msec()) / 1000.0) * 5.0))

	camera.target = aim.target
	update_sprites(delta)


func update_sprites(delta: float) -> void:
	var facing_left := aim.direction.x < 0

	## flip direction
	sprite.scale.x = lerpf(
		sprite.scale.x,
		-1 if facing_left else 1,
		10.0 * delta
	)

	var arm_dir := aim.target - arm.global_position

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

	var pupil_dir := (aim.target - pupils.global_position).normalized()
	var pupil_y_ratio = (pupil_dir.y + 1.0) / 2.0
	pupils.position.y = lerpf(pupils_min_y_offset, pupils_max_y_offset, pupil_y_ratio)
	

#endregion

#region Singal Recievers

func _on_hurt(_amount: int) -> void:
	camera.hitstop(0.2, 0.1)
	camera.shake(5.0, 1.0)
	

func _on_healed(_amount: int) -> void:
	pass # Replace with function body.

#endregion