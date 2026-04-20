class_name Charge
extends GhostState

@export var charge_time: float = 3.0
@export var recovery_time: float = 2.0

@export var charge_speed: float = 550.0

@export var damage := 4

@export var attack_area: Area2D

@export var animation: StringName
@export var next_state: State

var next: State
var recovery_timer: float
var charge_timer: float
var target: Vector2
var charging: bool = false


func on_start(msg := {}) -> void:
	if &"next" in msg:
		next = state_machine.state
	else:
		next = next_state if next_state else state_machine.default_state
	
	target = player.chase_target.global_position
	charging = false
	charge_timer = charge_time
	recovery_timer = recovery_time
	ghost.anim_player.play(animation)
	ghost.anim_player.animation_finished.connect(_on_animation_finished)
	attack_area.body_entered.connect(_on_attack_area_body_entered)

func on_end():
	ghost.anim_player.animation_finished.disconnect(_on_animation_finished)
	attack_area.body_entered.disconnect(_on_attack_area_body_entered)


func physics_update(delta: float) -> void:
	if charging:
		var dir := ghost.global_position.direction_to(target)
		ghost.velocity = dir * charge_speed
		charge_timer -= delta
		if charge_timer <= 0:
			charging = false
			recovery_timer = recovery_time
	else:
		if charge_timer <= 0:
			recovery_timer -= delta
			if recovery_timer <= 0:
				state_machine.change_state(next.name)

		ghost.velocity = ghost.velocity.move_toward(Vector2.ZERO, 20.0 * delta)

	ghost.move_and_slide()


func _on_animation_finished(_anim_name: StringName) -> void:
	charging = true


func _on_attack_area_body_entered(body: Node2D) -> void:
	if body == player:
		player.damage(damage, ghost)
