class_name OptionsMenu
extends Control

@export_file("*.tscn") var menu_scene_path: String

const MASTER_BUS := &"Master"
const MUSIC_BUS := &"Music"
const SFX_BUS := &"SFX"
const MIN_VOLUME_DB := -80.0

var confirm_delete: bool = false

@onready var master_volume_slider: HSlider = %master_volume_slider
@onready var music_volume_slider: HSlider = %music_volume_slider
@onready var sfx_volume_slider: HSlider = %sfx_volume_slider
@onready var speedrun_toggle: CheckButton = %speedrun_toggle
@onready var clear_data_button: Button = %ClearDataButton

func _ready() -> void:
	if not MusicManager.is_playing():
		MusicManager.start_menu()
	else:
		if not MusicManager.general_finished.is_connected(MusicManager.start_menu):
			MusicManager.general_finished.connect(MusicManager.start_menu, Node.CONNECT_ONE_SHOT)
	
	speedrun_toggle.button_pressed = Settings.speedrun
	master_volume_slider.set_value_no_signal(_get_bus_volume_linear(MASTER_BUS))
	music_volume_slider.set_value_no_signal(_get_bus_volume_linear(MUSIC_BUS))
	sfx_volume_slider.set_value_no_signal(_get_bus_volume_linear(SFX_BUS))

	clear_data_button.disabled = not Settings.has_persistent_data()

	if Input.get_connected_joypads().size() > 0:
		master_volume_slider.grab_focus.call_deferred()
	

func _on_back_button_pressed() -> void:
	if not menu_scene_path:
		push_error("no menu_scene_path set!")
		return
	Settings.save_persistent_data()
	SceneManager.change_scene(menu_scene_path)


func _on_master_volume_slider_value_changed(value: float) -> void:
	_set_bus_volume_linear(MASTER_BUS, value)


func _on_music_volume_slider_value_changed(value: float) -> void:
	_set_bus_volume_linear(MUSIC_BUS, value)


func _on_sfx_volume_slider_value_changed(value: float) -> void:
	_set_bus_volume_linear(SFX_BUS, value)


func _set_bus_volume_linear(bus_name: StringName, value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(bus_name), _linear_to_bus_db(value))


func _get_bus_volume_linear(bus_name: StringName) -> float:
	var volume_db := AudioServer.get_bus_volume_db(AudioServer.get_bus_index(bus_name))
	return 0.0 if volume_db <= MIN_VOLUME_DB else db_to_linear(volume_db)


func _linear_to_bus_db(value: float) -> float:
	return MIN_VOLUME_DB if value <= 0.0 else linear_to_db(value)


func _on_speedrun_toggled(toggled_on: bool) -> void:
	Settings.speedrun = toggled_on


func _on_clear_data_button_pressed() -> void:
	if not confirm_delete:
		clear_data_button.add_theme_color_override("font_color", Color.ORANGE_RED)
		clear_data_button.text = "CONFIRM?"
		confirm_delete = true
	else:
		clear_data_button.disabled = Settings.clear_persistent_data()
		clear_data_button.add_theme_color_override("font_color", Color.ORANGE)
		clear_data_button.text = "USER DATA CLEARED"
		confirm_delete = false
