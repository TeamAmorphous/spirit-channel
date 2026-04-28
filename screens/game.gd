extends Node2D

@export var game_over_scene: PackedScene

@onready var player: Player = $Player

func _ready() -> void:
	player.health.health_depleted.connect(_on_player_health_depleted)


func _on_player_health_depleted() -> void:
	if game_over_scene:
		SceneManager.change_scene_packed(game_over_scene)