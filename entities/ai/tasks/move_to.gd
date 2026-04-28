@tool
extends BTAction
## Moves the agent to the specified position, favoring horizontal movement. [br]
## Returns [code]SUCCESS[/code] when close to the target position (see [member tolerance]);
## otherwise returns [code]RUNNING[/code].

## Blackboard variable that stores the target position (Vector2)
@export var target_position_var := &"pos"

## Variable that stores desired speed (float)
@export var speed_var := &"speed"

## How close should the agent be to the target position to return SUCCESS.
@export var tolerance := 50.0

func _generate_name() -> String:
	return "MoveTo  pos: %s" % LimboUtility.decorate_var(target_position_var)


func _tick(delta: float) -> Status:
	var target_pos: Vector2 = blackboard.get_var(target_position_var, Vector2.ZERO)
	if target_pos.distance_to(agent.global_position) < tolerance:
		return SUCCESS

	var speed: float = blackboard.get_var(speed_var, 10.0)
	var desired_velocity: Vector2 = agent.global_position.direction_to(target_pos) * speed
	agent.move(delta, desired_velocity)
	agent.update_facing()
	return RUNNING