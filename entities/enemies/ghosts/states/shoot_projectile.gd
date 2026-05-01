@tool
class_name ShootProjectile
extends OneShotAnimation


@export var projectile_scene: PackedScene
@export var projectile_speed: float = 700.0
@export var min_flight_time: float = 0.45
@export var max_flight_time: float = 0.8
@export var projectile_damage: int = 1

@export var projectile_spawn_position: Node2D


func on_start(msg := {}):
	if not projectile_scene or not projectile_scene.can_instantiate():
		state_machine.revert()
	super.on_start(msg)
	ghost.facing = ghost.global_position.direction_to(player.chase_target.global_position)


func _spawn_projectile() -> void:
	if projectile_scene == null:
		return

	var projectile := projectile_scene.instantiate() as Node2D
	if projectile == null:
		return
	SceneManager.current_scene.add_sibling(projectile)

	var spawn_position := projectile_spawn_position.global_position if projectile_spawn_position else ghost.global_position
	var target_position := player.chase_target.global_position
	var distance := spawn_position.distance_to(target_position)
	var flight_time := clampf(distance / projectile_speed, min_flight_time, max_flight_time)

	projectile.global_position = spawn_position

	if projectile.has_method("launch_to"):
		projectile.call("launch_to", target_position, flight_time, projectile_damage)