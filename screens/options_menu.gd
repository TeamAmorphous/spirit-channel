class_name OptionsMenu
extends Control

@export_file("*.tscn") var menu_scene_path: String

const MASTER_BUS := &"Master"
const MUSIC_BUS := &"Music"
const SFX_BUS := &"SFX_Vol"
const MIN_VOLUME_DB := -80.0

@onready var master_volume_slider: HSlider = $CenterContainer/PanelContainer/VBoxContainer/VBoxContainer/Sliders/master_volume_slider
@onready var music_volume_slider: HSlider = $CenterContainer/PanelContainer/VBoxContainer/VBoxContainer/Sliders/music_volume_slider
@onready var sfx_volume_slider: HSlider = $CenterContainer/PanelContainer/VBoxContainer/VBoxContainer/Sliders/sfx_volume_slider


func _ready() -> void:
	master_volume_slider.set_value_no_signal(_get_bus_volume_linear(MASTER_BUS))
	music_volume_slider.set_value_no_signal(_get_bus_volume_linear(MUSIC_BUS))
	sfx_volume_slider.set_value_no_signal(_get_bus_volume_linear(SFX_BUS))

func _on_back_button_pressed() -> void:
	if not menu_scene_path:
		push_error("no menu_scene_path set!")
		return
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
