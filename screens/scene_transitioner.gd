extends Node
@onready var white_noise = $CanvasLayer

var _is_transitioning : bool = false

func transition_to_file(scene_path: String, duration: float = 0.5) -> void:
	if scene_path.is_empty():
		push_error("No scene path provided for transition.")
		return

	if _is_transitioning:
		return

	_is_transitioning = true
	var half_duration : float = maxf(duration * 0.5, 0.0)
	white_noise.start_transition()

	if half_duration > 0.0:
		await get_tree().create_timer(half_duration).timeout

	var error := get_tree().change_scene_to_file(scene_path)
	if error != OK:
		white_noise.stop_transition()
		_is_transitioning = false
		push_error("Failed to change scene to %s (error %d)." % [scene_path, error])
		return

	await get_tree().process_frame

	if half_duration > 0.0:
		await get_tree().create_timer(half_duration).timeout

	white_noise.stop_transition()
	_is_transitioning = false
