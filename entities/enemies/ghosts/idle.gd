extends GhostState

func on_start(_msg := {}) -> void:
	ghost.anim_player.play("idle")


func update(_delta: float) -> void:
	pass


func physics_update(delta: float) -> void:
	ghost.velocity = ghost.velocity.move_toward(Vector2.ZERO, ghost.decel * delta)


func input(_event: InputEvent) -> void:
	pass


func unhandled_input(_event: InputEvent) -> void:
	pass
