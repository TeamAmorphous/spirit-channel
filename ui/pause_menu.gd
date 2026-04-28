class_name PauseMenu
extends CanvasLayer

@export var hud: HUD

const PAUSE_ACTION := &"pause"
const MASTER_BUS := &"Master"
const MUSIC_BUS := &"Music"
const SFX_BUS := &"SFX"
const MIN_VOLUME_DB := -80.0

@onready var master_volume_slider: HSlider = $CenterContainer/PanelContainer/VBoxContainer/Content/Sliders/master_volume_slider
@onready var music_volume_slider: HSlider = $CenterContainer/PanelContainer/VBoxContainer/Content/Sliders/music_volume_slider
@onready var sfx_volume_slider: HSlider = $CenterContainer/PanelContainer/VBoxContainer/Content/Sliders/sfx_volume_slider


func _ready() -> void:
	hide()
	_sync_slider_values()


func _process(_delta: float) -> void:
	if not Input.is_action_just_pressed(PAUSE_ACTION):
		return
	if _is_page_open():
		return

	if visible:
		resume()
	else:
		pause()


func pause() -> void:
	if visible:
		return

	_sync_slider_values()
	show()
	get_tree().paused = true


func resume() -> void:
	if not visible:
		return

	hide()
	get_tree().paused = false


func _is_page_open() -> bool:
	return is_instance_valid(hud) and hud.is_page_open()


func _sync_slider_values() -> void:
	master_volume_slider.set_value_no_signal(_get_bus_volume_linear(MASTER_BUS))
	music_volume_slider.set_value_no_signal(_get_bus_volume_linear(MUSIC_BUS))
	sfx_volume_slider.set_value_no_signal(_get_bus_volume_linear(SFX_BUS))


func _on_resume_button_pressed() -> void:
	resume()


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
