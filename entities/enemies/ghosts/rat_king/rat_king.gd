extends Ghost

func _on_health_depleted() -> void:
	state_machine.change_state($"StateMachine/Pop")