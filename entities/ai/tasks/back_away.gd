@tool
extends BTAction

## Variable that stores desired speed (float)
@export var speed_var := &"speed"

## How far the back away position can deviate (in radians)
@export var max_angle_deviation := 0.7:
	set(a):
		max_angle_deviation = absf(a)

var _dir: Vector2
var _desired_velocity: Vector2


func _enter() -> void:
	_dir = Vector2.LEFT * agent.get_facing()
	var speed: float = blackboard.get_var(speed_var, 200.0)
	var rand_angle = randf_range(-max_angle_deviation, max_angle_deviation)
	_desired_velocity = _dir.rotated(rand_angle) * speed


func _tick(delta: float) -> Status:
	agent.move(delta, _desired_velocity)
	agent.face_dir(-signf(_dir.x))
	return RUNNING