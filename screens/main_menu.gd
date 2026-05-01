class_name MainMenu
extends Control


@export_file("*.tscn") var game_scene_path: String
@export_file("*.tscn") var options_scene_path: String

@onready var version_label = $MarginContainer/VersionLabel

func _ready() -> void:
	if not MusicManager.is_playing():
		MusicManager.start_menu()
	else:
		if not MusicManager.general_finished.is_connected(MusicManager.start_menu):
			MusicManager.general_finished.connect(MusicManager.start_menu, Node.CONNECT_ONE_SHOT)
	version_label.text = "v%s" % ProjectSettings.get_setting("application/config/version")


func _on_start_button_pressed() -> void:
	if not game_scene_path:
		push_error("no game_scene_path set!")
		return
	SceneManager.change_scene(game_scene_path)


func _on_options_button_pressed() -> void:
	if not options_scene_path:
		push_error("no options_scene_path set!")
		return
	SceneManager.change_scene(options_scene_path)


func _on_quit_button_pressed() -> void:
	get_tree().quit()
