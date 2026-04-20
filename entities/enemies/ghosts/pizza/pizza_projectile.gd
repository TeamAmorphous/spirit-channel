extends Area2D


@export var damage: int = 1
@export var lifetime: float = 2.5
@export var gravity_scale: float = 1.0


var velocity := Vector2.ZERO
var gravity_force: float = float(ProjectSettings.get_setting("physics/2d/default_gravity"))


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

	if body is StaticBody2D:
		queue_free()
