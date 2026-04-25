@tool
extends GhostState


@export var teleport_cooldown: float = 10.0
@export var teleport_cooldown_random_range: float = 5.0:
	set(v):
		teleport_cooldown_random_range = absf(v)

@export var teleport_distance: float = 800.0
@export var teleport_radius: float = 20.0

var teleport_timer: float

func on_start(_msg := {}) -> void:
	ghost.sprite.modulate.a = 0.0
	teleport_timer = teleport_cooldown + randf_range(
		-teleport_cooldown_random_range,
		teleport_cooldown_random_range
		)
	ghost.anim_player.play(&"idle")


func on_end() -> void:
	ghost.sprite.modulate = Color.WHITE


func update(delta: float) -> void:
	teleport_timer -= delta
	if teleport_timer <= 0:
		_teleport()


func physics_update(delta: float) -> void:
	ghost.velocity = ghost.velocity.move_toward(Vector2.ZERO, ghost.decel * delta)


func input(_event: InputEvent) -> void:
	pass


func unhandled_input(_event: InputEvent) -> void:
	pass


func _teleport() -> void:
	var player_facing_left := player.aim.direction.x < 0

	var tele_x_offset = teleport_distance if player_facing_left else -teleport_distance
	var tele_position := player.chase_target.global_position
	tele_position.x += tele_x_offset
	
	tele_position += Vector2(
		randf_range(-1.0, 1.0),
		randf_range(-.1, .1)
	).normalized() * teleport_radius

	ghost.global_position = tele_position

	state_machine.change_state($"../Appear")


func _on_flashed(from: Node2D) -> void:
	ghost.damage(1, from, $"../WaitDisappear")