extends PlayerState

func on_start(_msg := {}) -> void:
	player.movement_anim_player.play(&"idle")


func physics_update(delta: float) -> void:
	if not player.is_on_floor():
		state_machine.change_state("Fall", {jumped=false})
		return
	
	if Input.is_action_just_pressed(&"jump"):
		state_machine.change_state("Jump")
		return
	
	var direction := Input.get_axis(&"move_left", &"move_right")
	if direction:
		state_machine.change_state("Walk")
		return
	
	player.velocity.x = move_toward(player.velocity.x, 0, player.accel * 1.5 * delta)

	player.move_and_slide()