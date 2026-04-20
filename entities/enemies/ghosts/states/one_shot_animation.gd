class_name OneShotAnimation
extends GhostState

@export var animation: StringName
@export var play_backwards: bool = false
## Overriden by "next" key in on_start msg
@export var next_state: State

var next: State

func on_start(msg := {}) -> void:
	if not play_backwards:
		ghost.anim_player.play(animation)
	else:
		ghost.anim_player.play_backwards(animation)
	
	ghost.light_sensitivity.can_be_damaged = true
	if &"next" in msg:
		next = state_machine.get_node(msg.next)
	else:
		next = next_state if next_state else state_machine.default_state 
	ghost.anim_player.animation_finished.connect(_on_animation_finished)


func on_end() -> void:
	ghost.anim_player.animation_finished.disconnect(_on_animation_finished)


func _on_animation_finished(anim_name: StringName) -> void:
	if animation == anim_name:
		state_machine.change_state(next.name)
