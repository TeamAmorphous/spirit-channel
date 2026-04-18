class_name State
extends Node
## Parent class for all states and state machines.
## Has methods for all the normal Node input and update methods.

## The parent state machine. For all state-derived nodes, this will be [member Node.owner].
var state_machine : StateMachine

## Runs when the state is switched to, including when [member state_machine] is initalized.
## [param _msg] is a dictionary received from [method StateMachine.change_state], for passing variables between states.
func on_start(_msg := {}):
	pass

## Runs when the [member state_machine] switches to a different sibling state.
func on_end():
	pass

## Treat this the same as [Node._input].
func input(_event):
	pass

## Treat this the same as [Node._unhandled_input].
func unhandled_input(_event):
	pass

## Treat this the same as [Node._process].
func update(_delta):
	pass

## Treat this the same as [Node._physics_process].
func physics_update(_delta):
	pass

## This is used for getting the visual name of this state, used for debug purposes. For State, it is [member Node.name]. [param _sep] is used by [StateMachine.get_state_tree_name].
func get_state_tree_name(_sep := '>'):
	return name
