extends Area2D


@export var damage: int = 1
@export var lifetime: float = 2.5
@export var gravity_scale: float = 1.0
@export var angular_velocity: float = 200.0
@export var random_angular_direction: bool = true

var velocity := Vector2.ZERO
var gravity_force: float = float(ProjectSettings.get_setting("physics/2d/default_gravity"))


func _ready() -> void:
	rotation = randf_range(-PI, PI)
	if random_angular_direction:
		angular_velocity *= 1 if randf() < 0.5 else -1


func _process(delta: float) -> void:
	rotation_degrees += angular_velocity * delta


func _physics_process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return

	velocity.y += gravity_force * gravity_scale * delta
	global_position += velocity * delta
	rotation = velocity.angle()


func launch_to(target_position: Vector2, flight_time: float, new_damage: int = damage) -> void:
	damage = new_damage

	var time := maxf(flight_time, 0.01)
	var displacement := target_position - global_position
	velocity.x = displacement.x / time
	velocity.y = (displacement.y - (0.5 * gravity_force * gravity_scale * time * time)) / time


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		body.damage(damage, self)
		queue_free()
		return

	if body is PhysicsBody2D:
		queue_free()


func receive_flash(_from: Node2D) -> void:
	queue_free()