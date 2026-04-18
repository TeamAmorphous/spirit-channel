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
signal state_changed(state : State, msg : Dictionary)

## Emitted when any child [StateMachine] changes state. See [signal state_changed]
signal child_state_changed(state : State, msg : Dictionary)

## Used in [method StateMachine.wait_for_state], emitted when the timeout ends. Also emitted when [signal StateMachine.state_changed] is emitted.
## [color=yellow]For internal state machine use only.[/color]
signal _state_changed_timeout(state_name : String)

## Holds the msg from the last state change. Used in [method StateMachine.revert].
var last_msg : Dictionary

## State that the state machine gets initalized to on [method Node._ready].[br]
## [i]If this is not a top-level state machine, it will be used in [method StateMachine.engage_machine][/i]
@export var default_state : State

## Holds the previous state. Used in [method StateMachine.revert]. Default is [member StateMachine.default_state].
@onready var last_state : State = default_state

## Holds the current state. Default is [member StateMachine.default_state].
@onready var current_state : State = default_state

var _waits := 0

func _ready():
	set_process(false)
	set_physics_process(false)
	set_process_input(false)
	for child in get_children():
		if child is State:
			child.state_machine = self
		if child is StateMachine:
			child.state_changed.connect(_on_child_state_changed)
	state_changed.connect(_on_state_changed)
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
	state_changed.emit(current_state, msg)
	current_state.on_start(msg)

## See [method State.on_end].
func on_end():
	current_state.on_end()

#region top-level state machine
func _process(delta):
	if current_state:
		current_state.update(delta)
	
func _physics_process(delta):
	if current_state:
		current_state.physics_update(delta)

func _input(event):
	if current_state:
		current_state.input(event)

func _unhandled_input(event):
	if current_state:
		current_state.unhandled_input(event)
#endregion

#region sub-state machines only
## Calls [method State.update] on the [member StateMachine.current_state].
func update(delta):
	if current_state:
		current_state.update(delta)

## Calls [method State.physics_update] on the [member StateMachine.current_state].
func physics_update(delta):
	if current_state:
		current_state.physics_update(delta)

## Calls [method State.input] on the [member StateMachine.current_state].
func input(event):
	if current_state:
		current_state.input(event)

## Calls [method State.unhandled_input] on the [member StateMachine.current_state].
func unhandled_input(event):
	if current_state:
		current_state.unhandled_input(event)
#endregion


## Changes [member StateMachine.current_state] to the [State] named [param new_state_name].
## [param msg] is used for passing variables to the new state. See [method State.on_start].[br]
## Calls [method StateMachine.set_state].
func change_state(new_state_name : String, msg := {}):
	var new_state : State = get_node_or_null(new_state_name)
	if not is_instance_valid(new_state):
		if new_state_name:
			print(owner.name, ': Cannot change state to "', new_state_name, '" changing to "', default_state.name, '".')
		change_state(default_state.name, {fallback = true})
		return
	if new_state == current_state:
		return
	set_state(new_state, msg)


## Sets the current the state to the previous state.[br]
## See [method StateMachine.set_state]
func revert(msg := {}):
	if last_state != current_state:
		set_state(last_state, msg)


## Engages this state machine within its parent state machine.[br]
## [color=yellow]Only affects the parent state machine. This method does not affect any further up the hierarchy. (To be implemented in the future.)[/color]
func engage_machine(msg := {}):
	if state_machine:
		state_machine.set_state(self)
		set_state(default_state, msg)
	else:
		push_error("Trying to engage top-level state machine!")


## Calls [method StateMachine.change_state] on the parent state machine, with a top-level check.[br]
## If [param new_state_name] is not supplied, it sets the parent to its [member StateMachine.default_state].
func exit_machine(new_state_name := '', msg := {}):
	if state_machine:
		if not new_state_name or new_state_name.is_empty():
			new_state_name = state_machine.default_state.name
		state_machine.change_state(new_state_name, msg)
	else:
		push_error("Trying to exit top-level state machine!")


## Sets [StateMachine.current_state] to [param state], responsible for calling [param state]'s [method State.on_start] and the old [param state]'s [method State.on_end].
## Will wait for [member Node.owner] to be ready.
## This function also sets [member StateMachine.last_state] and [member StateMachine.last_msg].[br]
## Emits [signal StateMachine.state_changed].
func set_state(state : State, msg := {}):
	if not owner.is_node_ready():
		await owner.ready
	if current_state:
		current_state.on_end()
	last_state = current_state
	current_state = state
	last_msg = msg
	state_changed.emit(state, msg)
	state.on_start(msg)


## Coroutine that waits for the [StateMachine.current_state]'s [member Node.name] to equal [param target_state].[br]
func wait_for_state(target_state : String, timeout: float = 0) -> bool:
	if timeout > 0:
		get_tree().create_timer(timeout).timeout.connect(func(): _state_changed_timeout.emit('__TIMEOUT', {}))
	var state := ''
	_waits += 1
	while state != target_state:
		state = await _state_changed_timeout
		print(state)
		if state == '__TIMEOUT':
			_waits -= 1
			return false
	_waits -= 1
	return true


func in_state(to_check : Variant) -> bool:
	if to_check is Array:
		for tc in to_check:
			if in_state(tc):
				return true
	elif to_check is String:
		return current_state.name == to_check
	elif to_check is State:
		return current_state == State
	return false


## Calls the [member StateMachine.current_state]'s [method State.get_state_tree_name] and returns the 'state path', for debugging purposes.
func get_state_path_name() -> String:
	return current_state.name + (">" + current_state.get_state_path_name() if current_state is StateMachine else "")


## This method is connected to all children of this state machine's [signal State.child_state_changed].
func _on_child_state_changed(state : State, msg := {}):
	child_state_changed.emit(state, msg)

## Gets the name of this state machine and appends the [member StateMachine.current_state]'s [State.get_state_tree_name], with [param sep] as a separator.
func get_state_tree_name(sep := '>'):
	return ((name + ">") if state_machine != null else "") + current_state.get_state_tree_name(sep)

#region State


## See [method Global.save_state].
func save_path() -> StringName:
	return name


## See [method Global.save_state].
func save_state(dict: Dictionary, flags : Dictionary) -> void:
	if flags.get('same_room'):
		dict['State'] = current_state.name
		dict['StateParams'] = last_msg


## See [method Global.load_state].
func load_state(dict: Dictionary, flags : Dictionary) -> void:
	if flags.get('same_room'):
		change_state(dict.get('State', default_state.name), dict.get('StateParams', {}))


#endregion

#region Signals

## Connected to [signal StateMachine.state_changed]. Used to emit [signal StateMachine._state_changed_timeout].
func _on_state_changed(state : State, msg := {}):
	if state:
		_state_changed_timeout.emit(state.name, msg)

#endregion
