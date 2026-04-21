extends Chase

var timer := 2.0

func on_start(msg := {}) -> void:
	timer = 2.0
	super.on_start(msg)


func physics_update(delta: float) -> void:
	super.physics_update(delta)

	if player.global_position.distance_to(ghost.global_position) < 500.0:
		timer -= delta
		if timer <= 0.0:
			state_machine.change_state("Charge")
