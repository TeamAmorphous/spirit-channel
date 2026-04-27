@tool
extends PlayerState


func on_start(_msg := {}) -> void:
	player.is_invincible = true
	player.aim.mode = AimController.Mode.DISABLED


func on_end(_msg := {}) -> void:
	player.is_invincible = false
	player.aim.mode = AimController.Mode.NONE


func update(_delta: float) -> void:
	pass
