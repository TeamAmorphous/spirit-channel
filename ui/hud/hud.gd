class_name HUD
extends CanvasLayer


@export var player: Player


@onready var health_bar: OSDProgressBar = %HealthBar


func _ready() -> void:
	if player:
		health_bar.max_value = player.health.max_health
		health_bar.value = player.health.health
		player.health.max_health_changed.connect(_on_player_max_health_changed)
		player.health.health_changed.connect(_on_player_health_changed)


func _on_player_max_health_changed(max_health: int, _old: int) -> void:
	health_bar.max_value = max_health


func _on_player_health_changed(health: int, _old: int) -> void:
	health_bar.value = health