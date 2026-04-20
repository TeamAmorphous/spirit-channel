class_name GhostState
extends State

@onready var ghost: Ghost = owner as Ghost
var player: Player: get = get_player


func get_player() -> Player:
	if not player:
		player = get_tree().get_nodes_in_group(Player.PLAYER_GROUP).pop_front()
	return player