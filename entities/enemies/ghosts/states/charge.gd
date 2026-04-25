@tool
class_name Charge
extends GhostState

@export var windup_time: float = 0.5
@export var charge_time: float = 1.0
@export var recovery_time: float = 2.0

@export var charge_speed: float = 550.0

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


func on_start(msg := {}) -> void:
	if &"next" in msg:
		next = state_machine.state
	else:
		next = next_state if next_state else state_machine.default_state
	
	step = 0
	charging = false
	windup_timer = windup_time
	charge_timer = charge_time
	recovery_timer = recovery_time
	ghost.anim_player.play(animation)
	ghost.anim_player.animation_finished.connect(_on_animation_finished)
	attack_area.body_entered.connect(_on_attack_area_body_entered)


func on_end():
	ghost.anim_player.animation_finished.disconnect(_on_animation_finished)
	attack_area.body_entered.disconnect(_on_attack_area_body_entered)


func physics_update(delta: float) -> void:
	match step:
		0:
			ghost.velocity = ghost.velocity.move_toward(Vector2.ZERO, 20.0 * delta)
			windup_timer -= delta
			if windup_timer <= 0:
				var dir := ghost.global_position.direction_to(player.chase_target.global_position)
				ghost.velocity = dir * charge_speed
				step = 1
		1:
			charge_timer -= delta
			if charge_timer <= 0:
				step = 2
		2:
			ghost.velocity = ghost.velocity.move_toward(Vector2.ZERO, 20.0 * delta)
			recovery_timer -= delta
			if recovery_timer <= 0:
				step = 3
				state_machine.change_state(next)
			
	
	ghost.move_and_slide()


func _on_animation_finished(_anim_name: StringName) -> void:
	charging = true
	if stream:
		var sfx := AudioStreamPlayer.new()
		sfx.volume_db = 10.0
		sfx.stream = stream
		add_child(sfx)
		sfx.play()
		sfx.finished.connect(func(): sfx.queue_free())


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
