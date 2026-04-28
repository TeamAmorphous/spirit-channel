extends Control

@export var menu_scene: PackedScene

func _ready() -> void:
	Engine.time_scale = 1.0
	MusicManager.stop()
	$Label.visible = false


func _on_timer_timeout() -> void:
	$Label.visible = true


func _on_timer_2_timeout() -> void:
	if menu_scene:
		SceneManager.change_scene_packed(menu_scene)
	else:
		get_tree().quit()
