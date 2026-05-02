# Autoload: Settings
extends Node


const PERSISTENT_DATA_PATH := "user://persistent.gcsav"
const MASTER_BUS := &"Master"
const MUSIC_BUS := &"Music"
const SFX_BUS := &"SFX"
const MIN_VOLUME_DB := -80.0


signal save_failed
signal save_completed
signal load_failed
signal load_completed

var speedrun: bool = true

var clear_time: float = -1.0:
	set(t):
		clear_time = t
		best_time = t


var _last_best_time: float = -1.0
var best_time: float = -1.0:
	set(t):
		# First recorded time
		if best_time < 0:
			_last_best_time = best_time
			best_time = t
			return

		# Lower is better
		if t < best_time:
			_last_best_time = best_time
			best_time = t


func _ready() -> void:
	if has_persistent_data():
		load_persistent_data()


func is_new_best_time() -> bool:
	return (
		best_time >= 0
		and _last_best_time >= 0
		and best_time < _last_best_time
	)


func get_best_as_string() -> String:
	if best_time < 0:
		return "--:--:--"
	return format_time(best_time)


func get_last_clear_as_string() -> String:
	if clear_time < 0:
		return "--:--:--"
	return format_time(clear_time)


func format_time(time: float, sep := ":", digit := "%02d") -> String:
	var sr_hundreths := mini(int(fposmod(time, 1.0) * 100.0), 99)
	var sr_seconds := mini(int(time) % 60, 59)
	var sr_minutes := mini(int(time / 60.0) % 100, 99)
	return "%s%s%s%s%s" % [
		digit % sr_minutes,
		sep,
		digit % sr_seconds,
		sep,
		digit % sr_hundreths,
	]


func linear_to_bus_db(value: float) -> float:
	return MIN_VOLUME_DB if value <= 0.0 else linear_to_db(value)


func set_bus_volume_linear(bus_name: StringName, value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(bus_name), linear_to_bus_db(value))


func get_bus_volume_linear(bus_name: StringName) -> float:
	var volume_db := AudioServer.get_bus_volume_db(AudioServer.get_bus_index(bus_name))
	return 0.0 if volume_db <= MIN_VOLUME_DB else db_to_linear(volume_db)


func _save_settings() -> Dictionary:
	var volume := {}
	for bus in [MASTER_BUS, MUSIC_BUS, SFX_BUS]:
		volume[bus] = get_bus_volume_linear(bus)
	return {
		"speedrun": speedrun,
		"best_time": best_time,
		"volume": volume,
	}


func _load_settings(data: Dictionary) -> void:
	speedrun = data.get("speedrun", false)
	best_time = data.get("best_time", -1.0)
	var volume = data.get("volume")
	if typeof(volume) != TYPE_DICTIONARY:
		volume = {}
	for bus in [MASTER_BUS, MUSIC_BUS, SFX_BUS]:
		set_bus_volume_linear(bus, volume.get(bus, 1.0))


func save_persistent_data() -> bool:
	var save_file := FileAccess.open(PERSISTENT_DATA_PATH, FileAccess.WRITE)
	if not save_file:
		save_failed.emit()
		return false

	var data := _save_settings()
	save_file.store_var(data)
	save_completed.emit()
	return true


func load_persistent_data() -> bool:
	if not has_persistent_data():
		load_failed.emit()
		return false
	
	var save_file := FileAccess.open(PERSISTENT_DATA_PATH, FileAccess.READ)
	if not save_file:
		load_failed.emit()
		return false

	var data = save_file.get_var()

	if typeof(data) != TYPE_DICTIONARY:
		load_failed.emit()
		return false
	
	_load_settings(data)
	load_completed.emit()
	return true


func has_persistent_data() -> bool:
	return FileAccess.file_exists(PERSISTENT_DATA_PATH)


func clear_persistent_data() -> bool:
	if has_persistent_data():
		_load_settings({})
		return DirAccess.remove_absolute(PERSISTENT_DATA_PATH) == Error.OK
	return false
	