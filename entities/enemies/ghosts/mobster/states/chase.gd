@tool
extends Chase

@export var charge_trigger_distance: float = 450.0

func on_start(msg := {}) -> void:
	super.on_start(msg)


func physics_update(delta: float) -> void:
	super.physics_update(delta)

	if state_machine.current_state != self or not target or not player.chase_target:
		return

	if player.chase_target.global_position.distance_to(ghost.global_position) <= charge_trigger_distance:
		state_machine.change_state($"../Charge")
