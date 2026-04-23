class_name Interactable
extends Area2D

signal interacted_with(player: Player)

# EMITTED BY PLAYER
@warning_ignore_start("unused_signal")
signal on_player_can_interact
signal on_player_cannot_interact
@warning_ignore_restore("unused_signal")

@export var enabled := true
@export var repeatable := false

var fired := false


func can_interact() -> bool:
	if not enabled:
		return false
	if not repeatable and fired:
		return false
	return true


func interact(player: Player) -> void:
	if not can_interact():
		return
	fired = true
	interacted_with.emit(player)
