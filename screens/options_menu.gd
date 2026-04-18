class_name OptionsMenu
extends Control

@export_file("*.tscn") var menu_scene_path: String

func _on_back_button_pressed() -> void:
	if not menu_scene_path:
		push_error("no menu_scene_path set!")
		return
	get_tree().change_scene_to_file(menu_scene_path)