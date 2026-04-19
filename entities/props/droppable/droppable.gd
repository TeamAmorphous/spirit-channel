class_name Droppable
extends AnimatableBody2D

@export var random_angular_velocity: float = 2.0
@export var bounce_count: int = 3

var velocity := Vector2.ZERO
var angular_velocity := 0.0
var is_dropped := false

var bounces: int = 0

func _physics_process(delta: float) -> void:
	if not is_dropped:
		return
	
	velocity += get_gravity() * delta

	rotation += angular_velocity * delta

	var collision := move_and_collide(velocity * delta)

	if collision and collision.get_collider() is StaticBody2D:
		bounces += 1
		if bounces < bounce_count:
			velocity.y = -velocity.y / 2.0
		else:
			queue_free()


func drop(inital_velocity: Vector2) -> void:
	if is_dropped:
		return
	is_dropped = true

	var old_parent := get_parent()
	var old_position := global_position
	var new_parent := get_tree().current_scene
	old_parent.remove_child(self)
	new_parent.add_child(self)

	global_position = old_position

	velocity = inital_velocity
	if old_parent.owner is CharacterBody3D:
		velocity += old_parent.owner.velocity
	
	angular_velocity = randf_range(-random_angular_velocity, random_angular_velocity)
