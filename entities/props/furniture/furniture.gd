class_name Furniture
extends Node2D

@export var contains: Variant
@export var shake_length: float = 1.0
@export var shake_intensity: float = 10.0
@export var shake_sound: AudioStream

@onready var interactable: Interactable = $Interactable
@onready var sprite: Node2D = $Sprite
@onready var sound_player: AudioStreamPlayer2D = $AudioStreamPlayer2D


var shake_timer := 0.0


func _ready() -> void:
	sound_player.stream = shake_sound


func _process(delta: float) -> void:
	if shake_timer > 0.0:
		shake_timer -= delta
		sprite.position = Vector2(randf() - 0.5, randf() - 0.5) * 2.0 * shake_intensity
	else:
		sprite.position = Vector2.ZERO


func shake() -> void:
	shake_timer = shake_length


func _on_interacted_with(player: Player) -> void:
	shake()
	if contains is StringName:
		player.get_item(contains)
		
