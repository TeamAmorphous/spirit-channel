extends PlayerState

func on_start(msg := {}) -> void:
	player.movement_anim_player.play(&"hurt")
	player.aim.mode = AimController.Mode.DISABLED
	player.aim.target = player.aim.global_position
	if "from" in msg and msg["from"] is Node2D:
		var from2d := msg["from"] as Node2D
		var recoil_dir := -player.global_position.direction_to(from2d.global_position)
		player.velocity = Vector2(recoil_dir.x * 800, -800)


func on_end() -> void:
	player.aim.mode = AimController.Mode.NONE
	player.sprite.visible = true

func physics_update(delta: float) -> void:
	player.velocity += player.get_gravity() * delta

	
	player.move_and_slide()

	if player.is_on_floor():
		state_machine.change_state("Idle")
		return