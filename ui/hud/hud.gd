class_name HUD
extends CanvasLayer


@export var player: Player

@onready var logo_anim_player: AnimationPlayer = $Logo/AnimationPlayer

@onready var health_bar: OSDProgressBar = %HealthBar


func _ready() -> void:
	if player:
		health_bar.max_value = player.health.max_health
		health_bar.value = player.health.health
		player.health.max_health_changed.connect(_on_player_max_health_changed)
		player.health.health_changed.connect(_on_player_health_changed)


func _process(_delta: float) -> void:
	if randf() < 0.1 and not logo_anim_player.is_playing():
		logo_anim_player.play(&"default", 0.25)
	elif logo_anim_player.current_animation != &"RESET":
		logo_anim_player.play(&"RESET", 0.25)


func _on_player_max_health_changed(max_health: int, _old: int) -> void:
	health_bar.max_value = max_health


func _on_player_health_changed(health: int, _old: int) -> void:
	health_bar.value = health
