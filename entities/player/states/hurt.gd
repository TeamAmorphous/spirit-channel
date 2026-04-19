extends PlayerState

func on_start(_msg := {}) -> void:
	player.movement_anim_player.play(&"hurt")
	player.aim.mode = AimController.Mode.DISABLED
	player.aim.target = player.aim.global_position
	player.velocity.y = -500


func on_end() -> void:
	player.aim.mode = AimController.Mode.NONE
	player.sprite.visible = true

func physics_update(delta: float) -> void:
	player.velocity += player.get_gravity() * delta

	
	player.move_and_slide()

	if player.is_on_floor():
		state_machine.change_state("Idle")
		return