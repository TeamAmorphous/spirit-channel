extends Node2D

var previous_global_pos: Vector2

@export var stiffness: float = 20.0
@export var damping: float = 8.0

var _positions: Dictionary[Node2D, Vector2] = {}
var _velocities: Dictionary[Node2D, Vector2] = {}

func _physics_process(delta: float) -> void:
	for child in get_children():
		var child2d := child as Node2D
		if not child2d:
			continue

		var target := child2d.position

		if not (child2d in _positions):
			_positions[child2d] = target
			_velocities[child2d] = Vector2.ZERO
		
		var pos := _positions[child2d]
		var vel := _velocities[child2d]

		var force := (target - pos) * stiffness
		vel += force * delta
		vel *= exp(-damping * delta)

		pos += vel * delta

		_positions[child2d] = pos
		_velocities[child2d] = vel

		child2d.global_position = pos


func impulse(force: Vector2):
	for child in _velocities:
		_velocities[child] += force