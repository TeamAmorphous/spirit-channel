class_name SpeedrunTimer
extends Node

var time := 0.0
@export var pause_menu: PauseMenu

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta: float) -> void:
	if pause_menu and pause_menu.visible:
		return
	time += delta


func get_as_string() -> String:
	const DIGIT_FLASH_INT := 500
	return Settings.format_time(
		time,
		":" if Time.get_ticks_msec() % (DIGIT_FLASH_INT * 2) < DIGIT_FLASH_INT else " "
	)