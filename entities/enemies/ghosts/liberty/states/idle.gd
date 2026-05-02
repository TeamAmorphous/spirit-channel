@tool
extends "res://entities/enemies/ghosts/states/idle.gd"


@export var shades_cooldown: float = 5.0
@export var shades_cooldown_random: float = 2.0
@export var shades_get_state: State

var _shades_timer: float

func on_start(msg := {}) -> void:
	super.on_start(msg)
	_shades_timer = shades_cooldown + randf_range(-shades_cooldown_random, shades_cooldown_random)


func update(delta: float) -> void:
	super.update(delta)
	if not ghost.has_shades:
		_shades_timer -= delta
		if _shades_timer <= 0:
			state_machine.change_state(shades_get_state)