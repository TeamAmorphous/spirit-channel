@tool
class_name State
extends Node
## Parent class for all states and state machines.
## Has methods for all the normal Node input and update methods.

## The parent state machine. For all state-derived nodes, this will be [member Node.get_parent].
var state_machine: StateMachine

func _enter_tree() -> void:
	state_machine = get_parent() as StateMachine
	update_configuration_warnings()


## Runs when the state is switched to, including when [member state_machine] is initalized.
## [param _msg] is a dictionary received from [method StateMachine.change_state], for passing variables between states.
func on_start(_msg := {}):
	pass


## Runs when the [member state_machine] switches to a different sibling state.
func on_end():
	pass


## Treat this the same as [Node._input].
func input(_event: InputEvent):
	pass


## Treat this the same as [Node._unhandled_input].
func unhandled_input(_event: InputEvent):
	pass


## Treat this the same as [Node._process].
func update(_delta: float):
	pass


## Treat this the same as [Node._physics_process].
func physics_update(_delta: float):
	pass


## This is used for getting the visual name of this state, used for debug purposes. For State, it is [member Node.name]. [param _sep] is used by [StateMachine.get_state_tree_name].
func get_state_tree_name(_sep := '>'):
	return name


## Alias for [method StateMachine.change_state]. See [method StateMachine.change_state] for more details.
func goto(state: State, msg := {}):
	state_machine.change_state(state, msg)


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	if not state_machine:
		warnings.append("State is missing a reference to its parent StateMachine.")
	return warnings