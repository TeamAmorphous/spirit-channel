class_name PlayerCamera
extends Camera2D

@export var max_look_ahead := 400.0
@export var deadzone_radius := 100.0

@export var follow_speed := 10.0     # toward mouse
@export var return_speed := 4.0      # back to center
@export var lag_strength := 8.0      # camera lag

var current_offset := Vector2.ZERO
var shake_time: float = 0.0
var shake_duration: float = 0.0
var shake_strength: float = 0.0
var shake_offset := Vector2.ZERO

var hitstop_end_time: int = 0
var hitstop_scale: float = 0.0


var target: Vector2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if hitstop_end_time > 0:
		if Time.get_ticks_msec() >= hitstop_end_time:
			Engine.time_scale = 1.0
			hitstop_end_time = 0

	var to_target_pos := target - global_position
	var distance := to_target_pos.length()

	if distance < deadzone_radius:
		to_target_pos = Vector2.ZERO
		distance = 0.0

	var strength := clampf((distance - deadzone_radius) / 800.0, 0.0, 1.0)
	strength *= strength # << quadratic easing
	
	var target_offset := Vector2.ZERO
	if distance > 0:
		target_offset = to_target_pos.normalized() * max_look_ahead * strength

	var speed := follow_speed if target_offset.length_squared() > current_offset.length_squared() else return_speed
	current_offset = current_offset.lerp(target_offset, speed * delta)

	offset = offset.lerp(current_offset, lag_strength * delta)

	var real_delta := delta / maxf(Engine.time_scale, 0.0001)
	if shake_time > 0.0:
		shake_time -= real_delta
		var t := shake_time / shake_duration
		var falloff := t * t # << quadratic easing

		shake_offset = Vector2(
			randf_range(-1.0, 1.0),
			randf_range(-1.0, 1.0)
		) * shake_strength * falloff
	else:
		shake_offset = Vector2.ZERO
	
	offset += shake_offset
	

func shake(strength: float, duration: float) -> void:
	shake_strength = strength
	shake_duration = duration
	shake_time = duration


func hitstop(duration: float, time_scale: float = 0.0) -> void:
	hitstop_end_time = Time.get_ticks_msec() + int(duration * 1000)
	hitstop_scale = time_scale
	
	Engine.time_scale = time_scale