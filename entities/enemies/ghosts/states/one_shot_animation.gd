@tool
class_name OneShotAnimation
extends GhostState

@export var animation: StringName
@export var play_backwards: bool = false
## Overriden by "next" key in on_start msg
@export var next_state: State
@export var stream: AudioStream

var next: State

func on_start(msg := {}) -> void:
	if not play_backwards:
		ghost.anim_player.play(animation)
	else:
		ghost.anim_player.play_backwards(animation)
	
	if stream:
		var sfx := AudioStreamPlayer.new()
		sfx.stream = stream
		ghost.add_child(sfx)
		sfx.volume_db = 10.0
		sfx.play()
		sfx.finished.connect(func(): sfx.queue_free())


	ghost.light_sensitivity.can_be_damaged = true
	next = msg.get("next", state_machine.default_state) as State
	ghost.anim_player.animation_finished.connect(_on_animation_finished)


func on_end() -> void:
	ghost.anim_player.animation_finished.disconnect(_on_animation_finished)


func _on_animation_finished(anim_name: StringName) -> void:
	if animation == anim_name:
		state_machine.change_state(next)