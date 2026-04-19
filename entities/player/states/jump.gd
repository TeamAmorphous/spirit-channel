extends PlayerState

func on_start(_msg := {}) -> void:
	# todo: player.anim_player.play(&"jump")
	# todo: sound fx
	player.velocity.y = -player.jump_velocity


func physics_update(delta: float) -> void:
	var direction := Input.get_axis(&"move_left", &"move_right")
	if direction:
		player.velocity.x = move_toward(
			player.velocity.x,
			direction * player.speed,
			player.accel * delta
			)
	
	player.velocity += player.get_gravity() * delta
	
	player.move_and_slide()
	
	if player.is_on_floor():
		# todo: landing
		state_machine.change_state("Idle")
		return
	elif player.velocity.y > 0:
		state_machine.change_state("Fall", {jumped=true})
		return