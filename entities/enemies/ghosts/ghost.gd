class_name Ghost
extends Enemy

@onready var frequency: FrequencyComponent = $FrequencyComponent

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var shake_intensity: float
var shake_duration: float
var shake_timer: float

func shake(duration: float, intesity: float) -> void:
	shake_intensity = intesity
	shake_duration = duration


func _process(delta: float) -> void:
	if shake_duration > 0:
		shake_timer -= delta
		if shake_timer <= 0:
			shake_duration = 0
			shake_timer = 0
			shake_intensity = 0
		else:
			var effective_shake_intensity := (shake_timer / shake_duration) * shake_intensity
			var shake_offset := Vector2(
				randf_range(-1, 1),
				randf_range(-1, 1)
			).normalized() * effective_shake_intensity
			sprite.position = shake_offset
	else:
		sprite.position = Vector2.ZERO