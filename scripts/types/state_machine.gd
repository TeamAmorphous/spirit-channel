@tool
class_name StateMachine
extends State
## A finite state machine using the children of this node. Children must extend [State]. Delegates godot-standard [method Node._process] and similar to the [member StateMachine.current_state]
## [StateMachine] itself extends [State].[br]
##
## The inital state is determined by [member StateMachine.default_state].[br]
## If this is a top-level state machine, it will run [method StateMachine.on_start] when the owner of the state machine is ready.
## If this state machine is a child of another state machine, processing will be disabled.[br]
##
## [method Node._process], [method Node._physics_process], [method Node._input], and [method Node._unhandled_input] will be forwarded to the [member StateMachine.current_state][br]
## 
## [color=yellow]States cannot be named [code]__TIMEOUT[/code] or [method StateMachine.wait_for_state] will be broken.[/color]


## Emitted when the state machine finishes its [method Node._ready] method.
signal initialized

## Emitted when the current state is changed. [param state] is the state that was switched to. [param msg] is the inter-state communication dictionary.
signal state_changed(state: State, msg: Dictionary)

## Emitted when any child [StateMachine] changes state. See [signal state_changed]
signal child_state_changed(state: State, msg: Dictionary)

## Holds the msg from the last state change. Used in [method StateMachine.revert].
var last_msg: Dictionary

## State that the state machine gets initalized to on [method Node._ready].[br]
## [i]If this is not a top-level state machine, it will be used in [method StateMachine.engage_machine][/i]
@export var default_state: State

## Holds the previous state. Used in [method StateMachine.revert]. Default is [member StateMachine.default_state].
@onready var last_state: State = default_state

## Holds the current state. Default is [member StateMachine.default_state].
@onready var current_state: State = default_state

var active := false


func _ready():
	if Engine.is_editor_hint():
		return
	active = true
	set_process(false)
	set_physics_process(false)
	set_process_input(false)
	for child in get_children():
		if child is State:
			child.state_machine = self
		if child is StateMachine:
			child.state_changed.connect(_on_child_state_changed)
	await owner.ready
	if state_machine == null:
		current_state.on_start()
		set_process(true)
		set_physics_process(true)
		set_process_input(true)
		state_changed.connect(_on_child_state_changed)
	initialized.emit()


## See [method State.on_start]. Emits [signal StateMachine.state_changed].
## [param msg] is for giving variables/flags/data to the next state. (see [method StateMachine.change_state])
func on_start(msg := {}):
	active = true
	state_changed.emit(current_state, msg)
	current_state.on_start(msg)
	set_process(true)
	set_physics_process(true)
	set_process_input(true)


## See [method State.on_end].
func on_end():
	active = false
	set_process(false)
	set_physics_process(false)
	set_process_input(false)
	current_state.on_end()


#region top-level state machine
func _process(delta: float):
	if Engine.is_editor_hint():
		return
	if current_state:
		current_state.update(delta)


func _physics_process(delta: float):
	if Engine.is_editor_hint():
		return
	if current_state:
		current_state.physics_update(delta)


func _input(event: InputEvent):
	if Engine.is_editor_hint():
		return
	if current_state:
		current_state.input(event)


func _unhandled_input(event: InputEvent):
	if Engine.is_editor_hint():
		return
	if current_state:
		current_state.unhandled_input(event)
#endregion


#region sub-state machines only
## Calls [method State.update] on the [member StateMachine.current_state].
func update(delta: float):
	if current_state:
		current_state.update(delta)


## Calls [method State.physics_update] on the [member StateMachine.current_state].
func physics_update(delta: float):
	if current_state:
		current_state.physics_update(delta)


## Calls [method State.input] on the [member StateMachine.current_state].
func input(event: InputEvent):
	if current_state:
		current_state.input(event)


## Calls [method State.unhandled_input] on the [member StateMachine.current_state].
func unhandled_input(event: InputEvent):
	if current_state:
		current_state.unhandled_input(event)
#endregion


## Changes [member StateMachine.current_state] to the [State] [param state].
## [param msg] is used for passing variables to the new state. See [method State.on_start].[br]
## Calls [method StateMachine.set_state].
func change_state(target: State, msg := {}):
	if not is_instance_valid(target):
		print(owner.name, ': Cannot change state to "', target.name, '" changing to "', default_state.name, '".')
		change_state(default_state, {fallback = true})
		return
	var target_machine := target.state_machine
	
	# if within the same state machine, just change state
	if target_machine == self:
		_set_state(target, msg)
		return
	
	var current_chain := get_machine_chain()
	var target_chain := target_machine.get_machine_chain()
	var lca := Utility.find_lca(current_chain, target_chain) as StateMachine

	if not lca:
		push_error(owner.name + ": No route to state: " + target.name)
		return

	# climb up the state machine tree until we find the target state machine, calling on_end on the way
	var curr_machine: StateMachine = self
	while curr_machine and curr_machine != lca:
		curr_machine.on_end()
		curr_machine = curr_machine.state_machine

	# decend down the state machine tree until the target state machine, calling on_start on the way
	var idx := target_chain.find(lca)
	var i := idx + 1
	while i < target_chain.size():
		target_chain[i].on_start(msg)
		i += 1

	target_machine._set_state(target, msg)


## Sets the current the state to the previous state.[br]
## See [method StateMachine.set_state]
func revert(msg := {}):
	if last_state != current_state:
		_set_state(last_state, msg)


## Sets [StateMachine.current_state] to [param state], responsible for calling [param state]'s [method State.on_start] and the old [param state]'s [method State.on_end].
## This function also sets [member StateMachine.last_state] and [member StateMachine.last_msg].[br]
## Emits [signal StateMachine.state_changed].
func _set_state(state: State, msg := {}):
	if current_state:
		current_state.on_end()
	
	last_state = current_state
	current_state = state
	last_msg = msg

	state_changed.emit(current_state, msg)
	current_state.on_start(msg)


## Coroutine that waits for the [StateMachine.current_state]'s [member Node.name] to equal [param target_state].[br]
func wait_for_state(target: State, timeout: float = 0.0, process_always := true) -> bool:
	if current_state == target:
		return true
	
	var wait_state := {
		done = false,
		success = false,
	}

	var on_state_changed := func(state: State, _msg := {}) -> void:
		if wait_state.done:
			return
		if state == target:
			wait_state.done = true
			wait_state.success = true
	
	if timeout > 0.0:
		get_tree().create_timer(timeout, process_always).timeout.connect(func() -> void:
			if wait_state.done:
				return
			wait_state.done = true
			wait_state.success = false
		)
	
	state_changed.connect(on_state_changed)

	while not wait_state.done:
		await get_tree().process_frame

	state_changed.disconnect(on_state_changed)
	return wait_state.success


func in_state(to_check : Variant) -> bool:
	if to_check is Array:
		for s in to_check:
			if in_state(s):
				return true
	elif to_check is String or to_check is StringName:
		return current_state.name == to_check
	elif to_check is State:
		return current_state == to_check
	return false


func get_top_level_state_machine() -> StateMachine:
	var node: State = self
	while node:
		if node is StateMachine:
			return node
		node = node.state_machine
	return null


func get_machine_chain() -> Array[StateMachine]:
	var path: Array[StateMachine] = []
	var node: StateMachine = self

	while node:
		path.push_front(node)
		node = node.state_machine
	
	return path


## Calls the [member StateMachine.current_state]'s [method State.get_state_tree_name] and returns the 'state path', for debugging purposes.
func get_state_path_name(sep := '>') -> String:
	return current_state.name + (sep + current_state.get_state_path_name(sep) if current_state is StateMachine else "")


## This method is connected to all children of this state machine's [signal State.child_state_changed].
func _on_child_state_changed(state : State, msg := {}):
	child_state_changed.emit(state, msg)


## Gets the name of this state machine and appends the [member StateMachine.current_state]'s [State.get_state_tree_name], with [param sep] as a separator.
func get_state_tree_name(sep := '>'):
	return ((name + sep) if state_machine != null else "") + current_state.get_state_tree_name(sep)


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	if not default_state:
		warnings.append("State machine has no default state.")
	return warnings
