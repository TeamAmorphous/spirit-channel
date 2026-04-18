class_name MainMenu
extends Control


@export_file("*.tscn") var game_scene_path: String
@export_file("*.tscn") var options_scene_path: String


func _on_start_button_pressed() -> void:
	if not game_scene_path:
		push_error("no game_scene_path set!")
		return
	get_tree().change_scene_to_file(game_scene_path)


func _on_options_button_pressed() -> void:
	if not options_scene_path:
		push_error("no options_scene_path set!")
		return
	get_tree().change_scene_to_file(options_scene_path)


func _on_quit_button_pressed() -> void:
	get_tree().quit()
