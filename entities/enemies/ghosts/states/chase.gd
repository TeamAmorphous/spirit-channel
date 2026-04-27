@tool
class_name Chase
extends GhostState

@export var animation: StringName

@export var detection_area: Area2D
@export var attack_area: Area2D

@export var enabled: bool = true
@export var chase_speed: float = 800.0
@export var chase_accel: float = 200.0
@export var contact_damage: int = 2
@export var excluded_states: Array[String] = ["Hurt"]


var target: Player


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	if detection_area:
		detection_area.body_entered.connect(_on_detection_area_body_entered)
		detection_area.body_exited.connect(_on_detection_area_body_exited)
		detection_area.visible = true
		attack_area.body_entered.connect(_on_attack_area_body_entered)


# dangerous to put _process in a State, can cause fucky wucky if you are not careful!!!
# use update, physics_update, input, and unhandled_input functions instead,
# uses proper state machine control flow.
# - ceri

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if state_machine.current_state == self or not enabled:
		return
	if target and not state_machine.in_state(excluded_states):
		ghost.show_shock()
		state_machine.change_state(self)


func on_start(_msg := {}) -> void:
	if animation:
		ghost.anim_player.play(animation)


func physics_update(delta: float) -> void:
	if target and enabled:
		var dir_to_target := ghost.global_position.direction_to(player.chase_target.global_position).normalized()

		ghost.facing = dir_to_target
		ghost.velocity = ghost.velocity.move_toward(dir_to_target * chase_speed, chase_accel * delta)
		
	else:
		state_machine.change_state($"../Idle")

	ghost.move_and_slide()


func _on_detection_area_body_exited(body: Node2D) -> void:
	if body == target:
		target = null


func _on_detection_area_body_entered(body: Node2D) -> void:
	if body == player:
		target = body


func _on_attack_area_body_entered(body: Node2D) -> void:
	if state_machine.current_state != self or not enabled:
		return
	if body == target:
		target.damage(contact_damage, ghost)
