extends PlayerState


func on_start(_msg := {}) -> void:
	player.is_invincible = true
	player.aim.mode = AimController.Mode.DISABLED
	player.aim.target = player.aim.global_position


func on_end(_msg := {}) -> void:
	player.is_invincible = false
	player.aim.mode = AimController.Mode.NONE


func update(_delta: float) -> void:
	player.aim.target = player.aim.global_position
