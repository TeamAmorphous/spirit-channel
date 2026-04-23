extends Node2D

@onready var sprite = $Picture

@export var normal: Texture2D
@export var funny: Texture2D
@export_range(0, 1) var funny_chance: float = 0.02


func _ready() -> void:
	if funny:
		sprite.texture = funny if funny_chance <= randf() else normal
		