class_name Droppable
extends AnimatableBody2D

@export var initial_velocity: Vector2
@export var random_angular_velocity: float = 2.0
@export var bounce_count: int = 3
@export var max_lifetime: float = 10.0

var velocity := Vector2.ZERO
var angular_velocity := 0.0
var bounces: int = 0
@onready var lifetime := max_lifetime

func _ready() -> void:
	velocity = initial_velocity
	
	angular_velocity = randf_range(-random_angular_velocity, random_angular_velocity)


func _physics_process(delta: float) -> void:
	lifetime -= delta

	if lifetime <= 0.0:
		queue_free()
		return

	velocity += get_gravity() * delta

	rotation += angular_velocity * delta

	var collision := move_and_collide(velocity * delta)

	if collision:
		bounces += 1
		if bounces < bounce_count:
			velocity.y = -velocity.y / 2.0
		else:
			queue_free()
