extends Node2D

var previous_global_pos: Vector2

@export var stiffness: float = 20.0
@export var damping: float = 8.0
@export var max_distance: float = 200.0

var _rest_offsets: Dictionary[Node2D, Vector2] = {}
var _positions: Dictionary[Node2D, Vector2] = {}
var _velocities: Dictionary[Node2D, Vector2] = {}


func _physics_process(delta: float) -> void:
	for child in get_children():
		var child2d := child as Node2D
		if not child2d:
			continue

		if not (child2d in _positions):
			_positions[child2d] = child2d.global_position
			_velocities[child2d] = Vector2.ZERO
			_rest_offsets[child2d] = to_local(child2d.global_position)
		
		var target := to_global(_rest_offsets[child2d])

		var pos := _positions[child2d]
		var vel := _velocities[child2d]

		var force := (target - pos) * stiffness
		vel += force * delta
		vel -= vel * damping * delta

		pos += vel * delta

		if pos.distance_squared_to(target) > max_distance * max_distance:
			pos = target
			vel = Vector2.ZERO


		_positions[child2d] = pos
		_velocities[child2d] = vel

		child2d.global_position = pos
	
	for child in _positions:
		if not is_instance_valid(child) or child.get_parent() != self:
			_positions.erase(child)
			_velocities.erase(child)
			_rest_offsets.erase(child)


func reset_velocities() -> void:
	for child in _velocities:
		_velocities[child] = Vector2.ZERO

func impulse(force: Vector2):
	for child in _velocities:
		if is_instance_valid(child):
			_velocities[child] += force