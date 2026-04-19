extends GhostState

func on_start(_msg := {}) -> void:
	ghost.anim_player.play(&"poof")
	ghost.anim_player.animation_finished.connect(
		_on_animation_finished,
		Node.CONNECT_ONE_SHOT
		)
	ghost.light_sensitivity.enabled = false
	ghost.light_sensitivity.reset()
	ghost.velocity = Vector2.ZERO

func _on_animation_finished(_anim: StringName) -> void:
	ghost.queue_free()