class_name FrequencyComponent
extends Node


const MIN_FREQUENCY: float = -500.0
const MAX_FREQUENCY: float = 500.0


signal frequency_changed(old: float, new: float)


@export_range(MIN_FREQUENCY, MAX_FREQUENCY) var frequency: float = 0.0:
	set(value):
		value = clampf(value, MIN_FREQUENCY, MAX_FREQUENCY)
		if value == frequency:
			return
		var old := frequency
		frequency = value
		frequency_changed.emit(frequency, old)