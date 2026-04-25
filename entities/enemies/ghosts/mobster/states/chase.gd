@tool
extends Chase

func on_start(msg := {}) -> void:
	super.on_start(msg)


func physics_update(delta: float) -> void:
	super.physics_update(delta)

	if player.global_position.distance_to(ghost.global_position) < 1000.0:
		state_machine.change_state($"../Charge")
