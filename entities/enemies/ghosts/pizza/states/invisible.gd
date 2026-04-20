extends GhostState


@export var teleport_cooldown: float = 10.0
@export var teleport_cooldown_random_range: float = 5.0:
	set(v):
		teleport_cooldown_random_range = absf(v)

@export var teleport_distance: float = 1000.0
@export var teleport_radius: float = 300.0

var teleport_timer: float

func on_start(_msg := {}) -> void:
	ghost.sprite.visible = false
	ghost.light_sensitivity.can_be_damaged = false
	teleport_timer = teleport_cooldown + randf_range(
		-teleport_cooldown_random_range,
		teleport_cooldown_random_range
		)

func on_end() -> void:
	ghost.light_sensitivity.can_be_damaged = true


func update(delta: float) -> void:
	teleport_timer -= delta
	if teleport_timer <= 0 and not ghost.sprite.visible:
		_teleport()


func physics_update(_delta: float) -> void:
	pass


func input(_event: InputEvent) -> void:
	pass


func unhandled_input(_event: InputEvent) -> void:
	pass


func _teleport() -> void:
	var player_facing_left := player.aim.direction.x < 0

	var tele_x_offset = teleport_distance if player_facing_left else -teleport_distance
	var tele_position := player.global_position
	tele_position.x += tele_x_offset
	
	tele_position += Vector2(
		randf_range(-1.0, 1.0),
		randf_range(-.1, .1)
	).normalized() * teleport_radius

	ghost.global_position = tele_position

	state_machine.change_state("Appear", {next="ThrowPizza"})