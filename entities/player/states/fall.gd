extends PlayerState

@export var land_sound: AudioStream

var coyote_timer: float

func on_start(msg := {}) -> void:
	# todo: player.anim_player.play(&"jump")
	coyote_timer = player.coyote_time if msg.get("jumped") else 0.0


func physics_update(delta: float) -> void:
	var direction := Input.get_axis(&"move_left", &"move_right")
	if direction:
		player.velocity.x = move_toward(
			player.velocity.x,
			direction * player.speed,
			player.accel * delta
			)
	
	
	player.velocity += player.get_gravity() * delta

	player.move_and_slide()
	
	if player.is_on_floor():
		if direction:
			state_machine.change_state("Walk")
			return
		player.play_sound_effect(land_sound)
		state_machine.change_state("Idle")
		return

	if coyote_timer > 0:
		coyote_timer -= delta
		if Input.is_action_just_pressed(&"jump"):
			state_machine.change_state("Jump")
			return