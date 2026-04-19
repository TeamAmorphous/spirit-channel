extends GhostState

@export var stun_duration: float = 2.0

var next_state: String
var stun_timer: float


func on_start(msg := {}) -> void:
	stun_timer = stun_duration
	ghost.anim_player.play(&"hurt")
	next_state = msg.get("next", state_machine.last_state.name)
	if "from" in msg and msg["from"] is Player:
		var player := msg["from"] as Player
		var recoil_dir := -ghost.global_position.direction_to(player.chase_target.global_position)
		ghost.velocity = recoil_dir * 200
	ghost.light_sensitivity.enabled = false
	ghost.light_sensitivity.reset()


func on_end():
	ghost.light_sensitivity.enabled = true


func physics_update(delta) -> void:
	stun_timer -= delta
	if stun_timer <= 0:
		state_machine.change_state(next_state)
		return
	
	ghost.velocity.move_toward(Vector2.ZERO, ghost.decel * 2.0 * delta)
	
	ghost.move_and_slide()
