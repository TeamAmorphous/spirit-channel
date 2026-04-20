extends GhostState


@export var attack_interval: float = 5.0
@export var charge_duration: float = 1.0
@export var dash_duration: float = 0.55
@export var attack_sprite_path: NodePath = ^"../../Sprite/PunchSprite"
@export var chase_state_path: NodePath = ^"../Chase"
@export var idle_offset: Vector2 = Vector2.ZERO
@export var attack_offset: Vector2 = Vector2(28, -8)
@export var dash_speed: float = 550.0
@export var dash_accel: float = 2400.0


@onready var attack_sprite: AnimatedSprite2D = get_node_or_null(attack_sprite_path)
@onready var chase_state: Node = get_node_or_null(chase_state_path)

var attack_timer: float = attack_interval
var charge_timer: float = 0.0
var dash_timer: float = 0.0
var base_chase_speed: float = 0.0
var base_chase_accel: float = 0.0


func _ready() -> void:
	attack_timer = attack_interval
	if chase_state:
		base_chase_speed = chase_state.get("chase_speed")
		base_chase_accel = chase_state.get("chase_accel")
	if attack_sprite:
		attack_sprite.visible = false
		attack_sprite.offset = idle_offset


func _process(delta: float) -> void:
	if state_machine.current_state != chase_state:
		_reset_attack()
		return

	var target := _get_target()
	if target == null:
		_reset_attack()
		return

	if charge_timer > 0.0:
		charge_timer -= delta
		if charge_timer <= 0.0:
			_start_dash()
		return

	if dash_timer > 0.0:
		dash_timer -= delta
		if dash_timer <= 0.0:
			_end_attack_animation()
		return

	attack_timer -= delta
	if attack_timer > 0.0:
		return

	attack_timer = attack_interval
	_start_attack_animation()


func _get_target() -> Player:
	if chase_state == null:
		return null
	return chase_state.get("target") as Player


func _start_attack_animation() -> void:
	charge_timer = charge_duration
	if chase_state:
		chase_state.set("chase_speed", 0.0)
		chase_state.set("chase_accel", dash_accel)
	ghost.velocity = Vector2.ZERO
	_set_charge_visuals()


	if attack_sprite:
		attack_sprite.visible = true
		attack_sprite.offset = attack_offset


func _set_charge_visuals() -> void:
	ghost.sprite.stop()
	ghost.sprite.animation = &"attack"
	ghost.sprite.frame = 0

	if attack_sprite:
		attack_sprite.stop()
		attack_sprite.animation = &"attack"
		attack_sprite.frame = 0


func _start_dash() -> void:
	dash_timer = dash_duration
	if chase_state:
		chase_state.set("chase_speed", dash_speed)
		chase_state.set("chase_accel", dash_accel)
	ghost.anim_player.play(&"attack/mobster", -1.0, 1.0 / maxf(dash_duration, 0.01))
	_set_dash_visuals()


func _set_dash_visuals() -> void:
	ghost.sprite.stop()
	ghost.sprite.animation = &"attack"
	ghost.sprite.frame = 1

	if attack_sprite:
		attack_sprite.stop()
		attack_sprite.animation = &"attack"
		attack_sprite.frame = 1


func _end_attack_animation() -> void:
	if chase_state:
		chase_state.set("chase_speed", base_chase_speed)
		chase_state.set("chase_accel", base_chase_accel)

	if attack_sprite:
		attack_sprite.stop()
		attack_sprite.visible = false
		attack_sprite.offset = idle_offset

	if state_machine.current_state == chase_state:
		ghost.anim_player.play(ghost.idle_anim)
		ghost.sprite.play(ghost.idle_anim)


func _reset_attack() -> void:
	attack_timer = attack_interval
	charge_timer = 0.0
	dash_timer = 0.0
	_end_attack_animation()
