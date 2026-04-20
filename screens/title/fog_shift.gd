@tool
extends Sprite2D

@export var shift: float = 20.0
@export var frequency: float = 1.0

var time: float = 0

func _process(delta: float) -> void:
	time += delta
	offset = Vector2(
		shift * sin(time * TAU * frequency),
		0.0
	)