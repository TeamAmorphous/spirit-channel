class_name Player
extends CharacterBody2D

signal item_recieved(item: StringName)
signal item_lost(item: StringName)


const PLAYER_GROUP := &"player"

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

@onready var face_background: Sprite2D = $Sprite/FaceBackground
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
@onready var arm_collider_ray: RayCast2D = $Sprite/ArmColliderRay
@onready var reticle: Node2D = $Reticle

@onready var arrow_anim_player: AnimationPlayer = $ArrowAnimPlayer
@onready var arrow: Node2D = $Arrow

@onready var interaction_prompt = $InteractionPrompt

@export var footstep_sounds: Array[AudioStream]
@export var flashlight_click: AudioStream
@export var flashlight_flash: AudioStream

@export var low_health: AudioStream
@export var very_low_health: AudioStream

var inventory: Array[StringName]
var pages: int:
	get:
		return inventory.count(&"page")

var current_interactable: Interactable
var closest_ghost: Ghost

var channel: Ghost.Channel = Ghost.Channel.BLUE

var color_tween: Tween

var invincibility_timer: float
var is_invincible: bool
var flash_cooldown: float
var ghosts_in_beam: Array[Ghost]

const TRACK_TIMER_LENGTH := 3.0
var track_timer: float = TRACK_TIMER_LENGTH


func _ready() -> void:
	update_color()
	#Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	MusicManager.start()
	update_channel()
	MusicManager.snap_volume()


#region Process Functions

func _process(delta: float) -> void:
	camera.target = aim.target
	reticle.global_position = aim.target
	
	if invincibility_timer > 0:
		invincibility_timer -= delta
		if invincibility_timer < 0:
			invincibility_timer = 0
			is_invincible = false
	
	if flash_cooldown > 0:
		flash_cooldown -= delta
		if flash_cooldown < 0:
			flash_cooldown = 0
			play_sound_effect(flashlight_click)
			flashlight_beam.energy = 1.0
	
	reticle.visible = aim.mode == AimController.Mode.STICK
	
	if aim.mode != AimController.Mode.DISABLED:
		if flash_cooldown == 0:
			do_flashlight_damage(delta)

		if Input.is_action_just_pressed(&"primary_action"):
			flash()
		if Input.is_action_just_pressed(&"tune_up"):
			change_channel(1)
		elif Input.is_action_just_pressed(&"tune_down"):
			change_channel(-1)

		if Input.is_action_just_pressed(&"secondary_action"):
			if is_instance_valid(current_interactable) and state_machine.in_state(["Idle", "Walk"]):
				current_interactable.interact(self)
	
	track_timer -= delta
	if track_timer < 0.0:
		track_timer = TRACK_TIMER_LENGTH
		find_closest_ghost()
	update_sprites(delta)


func change_channel(dir: int) -> void:
	var old := channel
	channel = wrapi(channel + dir, 0, Ghost.Channel.values().size() - 1) as Ghost.Channel
	SignalBus.channel_changed.emit(channel, old)
	update_channel()


func update_channel() -> void:
	update_color()
	
	MusicManager.current_channel = channel
	for node in get_tree().get_nodes_in_group(Ghost.GHOST_GROUP):
		var ghost := node as Ghost
		if ghost:
			ghost.update_channel(channel)
	arrow_anim_player.play_backwards(&"show", 0.2)

	find_closest_ghost()


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
	arrow.modulate = color
	face_glow.color = color

	face_background.modulate = color.darkened(0.9)


func play_footstep_sound() -> void:
	if footstep_sounds.is_empty():
		push_warning("footstep_sounds is empty!")
		return
	play_sound_effect(footstep_sounds.pick_random() as AudioStream, )


func play_sound_effect(sound: AudioStream, from_offset: float = 0.0, volume_db: float = 1.0, pitch_scale: float = 1.0) -> void:
	sfx.play()
	var playback := sfx.get_stream_playback() as AudioStreamPlaybackPolyphonic
	playback.play_stream(sound, from_offset, volume_db, pitch_scale, AudioServer.PLAYBACK_TYPE_DEFAULT, &"SFX")


func find_closest_ghost() -> void:
	closest_ghost = null
	if channel == Ghost.Channel.NONE:
		return
	var ghosts := get_tree().get_nodes_in_group(Ghost.GHOST_GROUP)
	if not ghosts:
		return
	ghosts = ghosts.filter(func(a): return a.channel == channel)
	ghosts.sort_custom(
		func(a, b):
			return a.global_position.distance_squared_to(chase_target.global_position) < b.global_position.distance_squared_to(chase_target.global_position)
			)
	closest_ghost = ghosts.pop_front()


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
	

	if arm_collider_ray.is_colliding():
		var ray_collision_ratio := 1.0 - ((arm_collider_ray.global_position - arm_collider_ray.get_collision_point()).length_squared() / arm_collider_ray.target_position.length_squared())
		arm_angle = lerpf(arm_angle, deg_to_rad(arm_max_angle + 10), ray_collision_ratio)


	if facing_left:
		arm_angle = PI - arm_angle
	
	arm.global_rotation = lerp_angle(
		arm.global_rotation,
		arm_angle,
		20.0 * delta
	)

	var pupil_dir := (aim.target - pupils.global_position).normalized()
	var pupil_y_ratio = (pupil_dir.y + 1.0) / 2.0
	pupils.position.y = lerpf(pupils_min_y_offset, pupils_max_y_offset, pupil_y_ratio)
	
	if invincibility_timer > 0.0:
		sprite.visible = (int(invincibility_timer * 50.0) % 2) == 0
	else:
		sprite.visible = true
	
	if closest_ghost:
		var dir := arrow.global_position.direction_to(closest_ghost.global_position)
		arrow.rotation = lerp_angle(arrow.rotation, dir.angle(), 10.0 * delta)
		arrow_anim_player.play(&"show", 0.2)
	else:
		arrow_anim_player.play_backwards(&"show", 0.2)
	
	interaction_prompt.visible = is_instance_valid(current_interactable) and state_machine.in_state(["Idle", "Walk"])
	

#endregion

func damage(amount: int, from: Node = null) -> void:
	if is_invincible:
		return
	state_machine.change_state("Hurt", {"from": from})
	invincibility_timer = hurt_invincibility_length
	health.damage(amount)

	var from2d := from as Node2D
	if from2d:
		aim.target = from2d.global_position

	camera.hitstop(0.2, 0.1)
	camera.shake(5.0, 1.0)


func do_flashlight_damage(delta: float) -> void:
	for flashed in ghosts_in_beam:
		if flashed.has_node("LightSensitiveComponent"):
			flashed.get_node("LightSensitiveComponent").receive_light(delta * light_power_multiplier, self)


func flash() -> void:
	if flash_cooldown > 0 or aim.mode == AimController.Mode.DISABLED:
		# todo: bzzt
		return
	flash_cooldown = flash_cooldown_length

	# TEMPORARY!
	var flash_tween := get_tree().create_tween()
	flash_tween.tween_property(flashlight_beam, "energy", 0.0, 0.25).from(8.0)
	play_sound_effect(flashlight_flash)
	for flashed in ghosts_in_beam:
		if flashed.has_node("LightSensitiveComponent"):
			flashed.get_node("LightSensitiveComponent").receive_flash(self)


func _on_flashlight_area_body_entered(ghost_body: Node2D) -> void:
	if ghost_body is Ghost:
		ghosts_in_beam.append(ghost_body)


func _on_flashlight_area_body_exited(ghost_body: Node2D) -> void:
	if ghost_body in ghosts_in_beam:
		ghosts_in_beam.erase(ghost_body)


func _on_interactable_area_entered(area: Area2D) -> void:
	if current_interactable:
		return
	current_interactable = area as Interactable
	if not current_interactable.can_interact():
		current_interactable = null


func _on_interactable_area_exited(area: Area2D) -> void:
	if current_interactable == area:
		current_interactable = null


func add_item(item: StringName) -> void:
	inventory.append(item)
	item_recieved.emit(item)
	push_warning("Todo: ITEM GET STATE")


func remove_item(item: StringName) -> bool:
	var has_item := inventory.has(item)
	if has_item:
		inventory.erase(item)
		item_lost.emit(item)
	return has_item


func item_count(item: StringName) -> int:
	return inventory.count(item)


func walk_to(target: Vector2) -> void:
	movement_anim_player.play(&"walk")
	var left := global_position.x - target.x < 0
	aim.direction.x = -1.0 if left else 1.0
	var dist := (global_position - target).length()
	var walk_tween := get_tree().create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	walk_tween.tween_property(self, "global_position", target, dist / speed)
	await walk_tween.finished
	movement_anim_player.play(&"idle")