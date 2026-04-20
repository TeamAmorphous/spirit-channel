class_name OptionsMenu
extends Control

@export_file("*.tscn") var menu_scene_path: String

func _on_back_button_pressed() -> void:
	if not menu_scene_path:
		push_error("no menu_scene_path set!")
		return
	SceneManager.change_scene(menu_scene_path)


func _on_volume_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(value))
