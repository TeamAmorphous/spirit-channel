@tool
extends GhostState

@export var rat_scene: PackedScene
@export var rat_count: int = 3

func on_start(_msg := {}) -> void:
	ghost.anim_player.play(&"rat_king/pop")
	ghost.velocity = Vector2.ZERO
	ghost.anim_player.animation_finished.connect(_on_animation_finished)


func physics_update(_delta: float) -> void:
	ghost.velocity = Vector2.ZERO


func _on_animation_finished(_anim_name: StringName) -> void:
	if rat_scene and rat_scene.can_instantiate():
		for i in rat_count:
			var rat := rat_scene.instantiate() as Ghost
			var random_dir := Vector2(
				randf_range(-100.0, 100.0),
				randf_range(-100.0, 100.0)
			).normalized()
			ghost.add_sibling(rat)
			rat.global_position = ghost.global_position
			rat.state_machine.call_deferred("change_state", rat.state_machine.get_node("Hurt"))
			rat.velocity = random_dir * (1000.0 + (200.0 * randf()))
	await get_tree().process_frame
	ghost.queue_free()
