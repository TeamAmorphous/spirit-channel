@tool
class_name Charge
extends GhostState

@export var windup_time: float = 0.5
@export var charge_time: float = 1.0
@export var recovery_time: float = 2.0

@export var charge_speed: float = 550.0
@export var overshoot_distance: float = 120.0
@export var recovery_slide_factor: float = 0.3
@export var recovery_animation: StringName = &"idle"
@export var recovery_stop_threshold: float = 25.0

@export var damage := 4

@export var attack_area: Area2D

@export var animation: StringName
@export var next_state: State

@export var stream: AudioStream
@export var hit_stream: AudioStream

var next: State
var step: int
var windup_timer: float
var recovery_timer: float
var charge_timer: float
var charging: bool = false
var charge_direction := Vector2.ZERO
var charge_target_position := Vector2.ZERO
var recovery_animation_played := false

@onready var punch_sprite: AnimatedSprite2D = ghost.get_node_or_null("Sprite/PunchSprite") as AnimatedSprite2D

@onready var speed_lines: CanvasItem = ghost.get_node_or_null("Sprite/PunchSprite/SpeedLines") as CanvasItem


func on_start(msg := {}) -> void:
	if &"next" in msg:
		next = msg[&"next"] as State
	else:
		next = next_state if next_state else state_machine.default_state
	
	step = 0
	charging = false
	windup_timer = windup_time
	charge_timer = charge_time
	recovery_timer = recovery_time
	charge_direction = Vector2.ZERO
	charge_target_position = player.chase_target.global_position if player and player.chase_target else ghost.global_position
	recovery_animation_played = false
	if punch_sprite:
		punch_sprite.visible = false
		punch_sprite.frame = 0
	if speed_lines:
		speed_lines.visible = false
	ghost.anim_player.play(animation)
	attack_area.monitoring = true
	attack_area.body_entered.connect(_on_attack_area_body_entered)


func on_end():
	attack_area.body_entered.disconnect(_on_attack_area_body_entered)
	charging = false
	punch_sprite.visible = false


func physics_update(delta: float) -> void:
	match step:
		0:
			ghost.velocity = ghost.velocity.move_toward(Vector2.ZERO, ghost.decel * delta)
			if player and player.chase_target:
				ghost.facing = ghost.global_position.direction_to(player.chase_target.global_position)
			windup_timer -= delta
			if windup_timer <= 0:
				_begin_charge()
				step = 1
		1:
			ghost.velocity = charge_direction * charge_speed
			charge_timer -= delta
			if _has_reached_charge_target() or charge_timer <= 0:
				_finish_charge()
		2:
			ghost.velocity = ghost.velocity.move_toward(Vector2.ZERO, ghost.decel * 2.0 * delta)
			if not recovery_animation_played and recovery_animation and ghost.velocity.length() <= recovery_stop_threshold:
				ghost.anim_player.play(recovery_animation)
				recovery_animation_played = true
				step = 3
				state_machine.change_state(next)
				return
			recovery_timer -= delta
			if recovery_timer <= 0:
				step = 3
				state_machine.change_state(next)
			
	
	ghost.move_and_slide()


func _begin_charge() -> void:
	if player and player.chase_target:
		charge_target_position = player.chase_target.global_position
	charge_direction = ghost.global_position.direction_to(charge_target_position)
	if charge_direction.is_zero_approx():
		charge_direction = ghost.facing if not ghost.facing.is_zero_approx() else Vector2.RIGHT
	ghost.facing = charge_direction
	charging = true
	if stream:
		var sfx := AudioStreamPlayer.new()
		sfx.volume_db = 10.0
		sfx.stream = stream
		add_child(sfx)
		sfx.play()
		sfx.finished.connect(func(): sfx.queue_free())


func _finish_charge() -> void:
	charging = false
	ghost.velocity = charge_direction * charge_speed * recovery_slide_factor
	step = 2
	attack_area.monitoring = false


func _has_reached_charge_target() -> bool:
	var to_target := charge_target_position - ghost.global_position
	return to_target.dot(charge_direction) <= -overshoot_distance


func _on_attack_area_body_entered(body: Node2D) -> void:
	if not charging:
		return
	if body == player:
		if hit_stream:
			var sfx := AudioStreamPlayer.new()
			sfx.volume_db = 10.0
			sfx.stream = hit_stream
			add_child(sfx)
			sfx.play()
			sfx.finished.connect(func(): sfx.queue_free())
		player.damage(damage, ghost)
		attack_area.set_deferred("monitoring", false)
		
