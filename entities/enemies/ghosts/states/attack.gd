extends GhostState


@export var attack_interval: float = 1.0
@export var spawn_delay: float = 0.15
@export var projectile_scene: PackedScene
@export var projectile_speed: float = 700.0
@export var min_flight_time: float = 0.45
@export var max_flight_time: float = 0.8
@export var projectile_damage: int = 1
@export var attack_sprite_path: NodePath = ^"../../Sprite/PizzaAttack"
@export var chase_state_path: NodePath = ^"../Chase"


@onready var attack_sprite: AnimatedSprite2D = get_node_or_null(attack_sprite_path)
@onready var chase_state: Node = get_node_or_null(chase_state_path)

var attack_timer: float = attack_interval
var spawn_timer: float = 0.0
var pending_throw: bool = false


func _ready() -> void:
	attack_timer = attack_interval
	if attack_sprite:
		attack_sprite.visible = false
		attack_sprite.animation_finished.connect(_on_attack_animation_finished)


func _process(delta: float) -> void:
	if state_machine.current_state != chase_state:
		_reset_attack()
		return

	var target := _get_target()
	if target == null:
		_reset_attack()
		return

	if pending_throw:
		spawn_timer -= delta
		if spawn_timer <= 0.0:
			pending_throw = false
			_spawn_projectile(target)
		return

	attack_timer -= delta
	if attack_timer > 0.0:
		return

	attack_timer = attack_interval
	pending_throw = true
	spawn_timer = spawn_delay

	if attack_sprite:
		attack_sprite.visible = true
		attack_sprite.play(&"attack")
		ghost.sprite.play(&"attack")


func _get_target() -> Player:
	if chase_state == null:
		return null
	return chase_state.get("target") as Player


func _spawn_projectile(target: Player) -> void:
	if projectile_scene == null or not is_instance_valid(target):
		return

	var projectile := projectile_scene.instantiate() as Node2D
	if projectile == null:
		return

	var parent := get_tree().current_scene
	if parent == null:
		parent = ghost.get_parent()
	parent.add_child(projectile)

	var spawn_position := attack_sprite.global_position if attack_sprite else ghost.global_position
	var target_position := target.chase_target.global_position
	var distance := spawn_position.distance_to(target_position)
	var flight_time := clampf(distance / projectile_speed, min_flight_time, max_flight_time)

	projectile.global_position = spawn_position
	ghost.facing = spawn_position.direction_to(target_position)

	if projectile.has_method("launch_to"):
		projectile.call("launch_to", target_position, flight_time, projectile_damage)


func _reset_attack() -> void:
	pending_throw = false
	spawn_timer = 0.0
	attack_timer = attack_interval

	if attack_sprite:
		attack_sprite.stop()
		attack_sprite.visible = false


func _on_attack_animation_finished() -> void:
	if attack_sprite and attack_sprite.animation == &"attack":
		attack_sprite.visible = false
