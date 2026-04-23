extends Control


func _ready() -> void:
	SignalBus.static_interference.emit(20.0)


func _on_timer_timeout() -> void:
	$Label.visible = true


func _on_timer_2_timeout() -> void:
	get_tree().quit()
