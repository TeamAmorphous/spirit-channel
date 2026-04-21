extends Node2D


enum DoorState {
	CLOSED,
	OPEN_RIGHT,
	OPEN_LEFT
}

@export var needs_item: StringName
var state := DoorState.CLOSED
var occupied: int = 0
var showing_lock: bool = false

@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var lock_anim_player: AnimationPlayer = $LockAnimPlayer
@onready var open_sound: AudioStreamPlayer = $OpenSound
@onready var closed_sound: AudioStreamPlayer = $CloseSound
@onready var unlock_sound: AudioStreamPlayer = $UnlockSound


func _ready() -> void:
	anim_player.play(&"closed")


func can_open(player: Player) -> bool:
	if needs_item:
		return player.item_count(needs_item) > 0
	return true


func set_state(new_state: DoorState) -> void:
	if state == new_state:
		return
	if state != DoorState.CLOSED and occupied > 0:
		return
	
	var old: DoorState = state
	state = new_state
	anim_player.clear_queue()
	match state:
		DoorState.CLOSED:
			match old:
				DoorState.OPEN_LEFT:
					anim_player.play_backwards(&"left")
					anim_player.animation_finished.connect(closed_sound.play.bind(0).unbind(1), CONNECT_ONE_SHOT)
					anim_player.queue(&"closed")
				DoorState.OPEN_RIGHT:
					anim_player.play_backwards(&"right")
					anim_player.animation_finished.connect(closed_sound.play.bind(0).unbind(1), CONNECT_ONE_SHOT)
					anim_player.queue(&"closed")
		DoorState.OPEN_LEFT:
			if old == DoorState.CLOSED:
				open_sound.play()
				anim_player.play(&"left")
		DoorState.OPEN_RIGHT:
			if old == DoorState.CLOSED:
				open_sound.play()
				anim_player.play(&"right")


func _on_enter_from(left: bool, player: Player) -> void:
	if can_open(player):
		if needs_item:
			player.remove_item(needs_item)
			needs_item = &""
			unlock_sound.play()
			showing_lock = false
		set_state(DoorState.OPEN_LEFT if left else DoorState.OPEN_RIGHT)


func _on_exit_from(_left: bool, _player: Player) -> void:
	set_state(DoorState.CLOSED)


func _on_left_area_body_entered(body: Node2D) -> void:
	var player: Player = body as Player
	_on_enter_from(true, player)


func _on_left_area_body_exited(body: Node2D) -> void:
	var player: Player = body as Player
	_on_exit_from(true, player)


func _on_right_area_body_entered(body: Node2D) -> void:
	var player: Player = body as Player
	_on_enter_from(false, player)


func _on_right_area_body_exited(body: Node2D) -> void:
	var player: Player = body as Player
	_on_exit_from(false, player)


func _on_inside_area_body_entered(body: Node2D) -> void:
	occupied += 1
	
	var player: Player = body as Player
	if not can_open(player):
		if player.global_position.x < global_position.x:
			lock_anim_player.play(&"show_left")
		else:
			lock_anim_player.play(&"show_right")
		showing_lock = true
				


func _on_inside_area_body_exited(body: Node2D) -> void:
	occupied -= 1
	
	if occupied <= 0:
		occupied = 0
		set_state(DoorState.CLOSED)
	
	if showing_lock:
		var player: Player = body as Player
		if player.global_position.x < global_position.x:
			lock_anim_player.play_backwards(&"show_left")
		else:
			lock_anim_player.play_backwards(&"show_right")
		showing_lock = false
