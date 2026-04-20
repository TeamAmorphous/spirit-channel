class_name AimController
extends Marker2D


const SWITCH_THRESHOLD := 0.6
const MOUSE_DEADZONE := 5.0
const MOUSE_MAX_DIST := 1000.0
const STICK_DEADZONE := 0.2
const STICK_AIM_DISTANCE := 1000.0
const STICK_AIM_LAG := 20.0


enum Mode {
	MOUSE,
	STICK,
	NONE,
	DISABLED,
}


@export var mouse_sensitivity: float = 1.0


var mode: Mode = Mode.MOUSE
var target: Vector2 = Vector2.ZERO
var direction: Vector2 = Vector2.RIGHT
var last_direction: Vector2 = Vector2.ZERO


func _process(delta: float) -> void:
	var stick_input := Input.get_vector(&"aim_left", &"aim_right", &"aim_up", &"aim_down")
	var stick_strength := stick_input.length()
	var mouse_strength := Input.get_last_mouse_velocity().length()

	match mode:
		Mode.MOUSE:
			if stick_strength > SWITCH_THRESHOLD:
				mode = Mode.STICK
				return
			target = get_global_mouse_position()
			last_direction = global_position.direction_to(target)
		
		Mode.STICK:
			if stick_strength < STICK_DEADZONE and mouse_strength > MOUSE_DEADZONE:
				mode = Mode.MOUSE
				return
			var stick_target := global_position + stick_input.normalized() * STICK_AIM_DISTANCE * lerpf(STICK_DEADZONE, 1.0, stick_strength)
			if stick_strength > STICK_DEADZONE:
				target = target.lerp(stick_target, STICK_AIM_LAG * delta)
				last_direction = stick_input.normalized()
			else:
				mode = Mode.NONE
		
		Mode.NONE:
			if stick_strength > STICK_DEADZONE:
				mode = Mode.STICK
				return
			if mouse_strength > MOUSE_DEADZONE:
				mode = Mode.MOUSE
				return
			target = global_position + (last_direction * STICK_AIM_DISTANCE * STICK_DEADZONE)
		
		Mode.DISABLED:
			pass

	direction = (target - global_position).normalized()