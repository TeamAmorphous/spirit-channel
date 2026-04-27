@tool
extends Chase

@onready var hot_dog: Sprite2D = %HotDog 

var timer = 2.0

func physics_update(delta: float) -> void:
	super.physics_update(delta)

	if hot_dog.visible and animation == &"idle":
		if player.global_position.distance_to(ghost.global_position) > 1000.0:
			timer -= delta
			if timer <= 0.0:
				state_machine.change_state($"../HotDogThrow")
