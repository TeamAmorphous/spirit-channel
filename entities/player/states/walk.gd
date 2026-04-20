extends PlayerState

func on_start(_msg := {}) -> void:
	player.movement_anim_player.play(&"walk")


func on_end():
	player.movement_anim_player.speed_scale = 1.0


func physics_update(delta: float) -> void:
	var direction := Input.get_axis(&"move_left", &"move_right")
	if direction:
		player.movement_anim_player.speed_scale = absf(direction)
		player.velocity.x = move_toward(
			player.velocity.x,
			direction * player.speed,
			player.accel * delta
			)
	
		if sign(direction) != sign(player.aim.direction.x):
			player.movement_anim_player.play_backwards(&"walk")

	player.velocity += player.get_gravity() * delta

	player.move_and_slide()

	if not player.is_on_floor():
		state_machine.change_state("Fall")
		return
	
	if Input.is_action_just_pressed(&"jump"):
		state_machine.change_state("Jump")
		return
	
	if not direction:
		state_machine.change_state("Idle")
		return
	
