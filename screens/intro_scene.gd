extends Control


@export var next_scene: PackedScene


func _on_timer_timeout() -> void:
	MusicManager.stop()
	SceneManager.change_scene_packed(next_scene)
