class_name Player
extends CharacterBody2D


const SWITCH_THRESHOLD := 0.6
const MOUSE_DEADZONE := 5.0
const STICK_DEADZONE := 0.2
const STICK_AIM_DISTANCE := 1000.0
const STICK_AIM_LAG := 20.0


@export_category("Physics")
@export var speed: float = 800.0
@export var accel: float = 1500.0
@export var jump_velocity: float = 800.0
@export var coyote_time: float = 0.25 ## seconds

@export_category("Gameplay")
@export var light_power_multiplier: float = 1.0
@export var flash_cooldown_length: float = 5.0
@export var flash_damage: int = 1
@export var hurt_invincibility_length: float = 3.0 

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
@onready var eyes: AnimatedSprite2D = $Sprite/Body/Eyes
@onready var pupils: Sprite2D = $Sprite/Body/Eyes/Pupils
@onready var face_glow: PointLight2D = $Sprite/Body/FaceGlow

@onready var movement_anim_player: AnimationPlayer = $MovementAnimPlayer
@onready var sfx: AudioStreamPlayer = $SFX

@onready var chase_target: Marker2D = $ChaseTarget

@onready var flashlight_beam_area: Area2D = $FlashlightArea
@onready var flashlight_beam: PointLight2D = $Sprite/Arm/FlashlightBeam

@onready var health: HealthComponent = $HealthComponent

@onready var state_machine: StateMachine = $StateMachine
@onready var aim: AimController = $AimController

@export var footstep_sounds: Array[AudioStream]

var channel: Ghost.Channel = Ghost.Channel.NONE

var color_tween: Tween

var invincibility_timer: float
var is_invincible: bool
var flash_cooldown: float

func _ready() -> void:
	update_color()
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	MusicManager.start()

#region Process Functions

func _process(delta: float) -> void:
	camera.target = aim.target
	
	if invincibility_timer > 0:
		invincibility_timer -= delta
		if invincibility_timer < 0:
			invincibility_timer = 0
	
	if flash_cooldown > 0:
		flash_cooldown -= delta
		if flash_cooldown < 0:
			flash_cooldown = 0
			flashlight_beam.energy = 1.0

	is_invincible = invincibility_timer > 0
	
	if aim.mode != AimController.Mode.DISABLED and flash_cooldown == 0:
		do_flashlight_damage(delta)

	if Input.is_action_just_pressed(&"primary_action"):
		flash()
	if Input.is_action_just_pressed(&"tune_up"):
		tune_up()
	elif Input.is_action_just_pressed(&"tune_down"):
		tune_down()
	
	update_sprites(delta)


func tune_up() -> void:
	channel = wrapi(channel + 1, 0, Ghost.Channel.values().size() - 1) as Ghost.Channel
	update_channel() 


func tune_down() -> void:
	channel = wrapi(channel - 1, 0, Ghost.Channel.values().size() - 1) as Ghost.Channel
	update_channel() 


func update_channel() -> void:
	update_color()
	
	MusicManager.current_channel = channel
	for node in get_tree().get_nodes_in_group(Ghost.GHOST_GROUP):
		var ghost := node as Ghost
		if ghost:
			ghost.update_channel(channel)


func update_color() -> void:
	if color_tween and color_tween.is_running():
		color_tween.kill()
	var color := Ghost.CHANNEL_COLORS[channel]
	color_tween = get_tree().create_tween()
	color_tween.set_ease(Tween.EaseType.EASE_IN).set_trans(Tween.TransitionType.TRANS_ELASTIC).set_parallel(true)
	color_tween.tween_property(eyes, "scale:y", 1.0, 0.2).from(0.0)
	color_tween.tween_property(face_glow, "energy", 0.75, 0.2).from(0.0)
	#color_tween.tween_property(flashlight_beam, "color", color.lightened(0.2), 0.1).from_current()
	#color_tween.tween_property(flashlight_beam, "energy", 1.0, 0.1).from(0.0)
	eyes.modulate = color
	face_glow.color = color
	tv.color = color.darkened(0.8)

func play_footstep_sound() -> void:
	var sound := footstep_sounds.pick_random() as AudioStream
	var playback := sfx.get_stream_playback() as AudioStreamPlaybackPolyphonic
	playback.play_stream(sound)


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
	
	if is_invincible:
		sprite.visible = (int(invincibility_timer * 50.0) % 2) == 0
	else:
		sprite.visible = true

#endregion

func damage(amount: int, from: Node = null) -> void:
	if is_invincible:
		return
	state_machine.change_state("Hurt")
	invincibility_timer = hurt_invincibility_length
	health.damage(amount)

	var from2d := from as Node2D
	if from2d:
		aim.target = from2d.global_position

	camera.hitstop(0.2, 0.1)
	camera.shake(5.0, 1.0)


func do_flashlight_damage(delta: float) -> void:
	for flashed in flashlight_beam_area.get_overlapping_bodies():
		if flashed.has_node("LightSensitiveComponent"):
			flashed.get_node("LightSensitiveComponent").receive_light(delta * light_power_multiplier, self)


func flash() -> void:
	if flash_cooldown > 0 or aim.mode == AimController.Mode.DISABLED:
		# todo: bzzt
		return
	flash_cooldown = flash_cooldown_length

	# TEMPORARY!
	var flash_tween := get_tree().create_tween()
	flash_tween.tween_property(flashlight_beam, "energy", 0.0, 0.25).from(3.0)

	for flashed in flashlight_beam_area.get_overlapping_bodies():
		if flashed.has_node("LightSensitiveComponent"):
			flashed.get_node("LightSensitiveComponent").receive_flash(self)

	
