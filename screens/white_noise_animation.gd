extends CanvasLayer

@onready var texture_rect : ColorRect = $TextureRect

var _is_transitioning : bool = false

func _ready() -> void:
	texture_rect.hide()


func start_transition() -> void:
	_is_transitioning = true
	texture_rect.show()


func stop_transition() -> void:
	_is_transitioning = false
	texture_rect.hide()
