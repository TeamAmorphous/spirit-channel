class_name Wait
extends GhostState

@export var length := 2.0
@export var animaton: StringName
@export var next_state: State

var timer: float
var next: State

func on_start(msg := {}) -> void:
	timer = msg.get("length", length)
	if &"next" in msg:
		next = state_machine.state
	else:
		next = next_state if next_state else state_machine.default_state 
	if animaton:
		ghost.anim_player.play(animaton)


func update(delta: float) -> void:
	timer -= delta
	if timer <= 0:
		state_machine.change_state(next.name)