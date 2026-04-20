extends Sprite2D

@export var delay: float = 2.0
@export var amount: float = -200
@export var speed: float = 20.0

var timer: float

func _ready() -> void:
	timer = delay
	offset.x = -amount


func _update(delta: float) -> void:
	if timer > 0:
		timer -= delta
	else:
		offset.x = lerpf(offset.x, 0.0, speed * delta)