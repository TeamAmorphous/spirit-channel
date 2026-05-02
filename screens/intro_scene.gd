extends Control


@export var next_scene: PackedScene


func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed(&"primary_action") \
			or Input.is_action_just_pressed(&"ui_accept") \
			or Input.is_action_just_pressed(&"ui_cancel"):
		_on_skip_button_pressed()


func _on_timer_timeout() -> void:
	MusicManager.stop()
	SceneManager.change_scene_packed(next_scene)


func _on_skip_button_pressed() -> void:
	MusicManager.stop()
	SceneManager.change_scene_packed(next_scene)
