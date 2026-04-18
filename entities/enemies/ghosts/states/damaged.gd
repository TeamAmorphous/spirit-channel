extends GhostState

@export var stun_duration: float = 2.0

var next_state: String
var stun_timer: float


func on_start(msg := {}):
	stun_timer = stun_duration
	ghost.sprite.play(&"damage")
	next_state = msg.get("next", state_machine.last_state.name)


func update(delta):
	stun_timer -= delta
	if stun_timer <= 0:
		state_machine.change_state(next_state)