extends Node2D
@onready var white_noise : CanvasLayer = $CanvasLayer

var current_level : Node2D = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	current_level = $InitialScene


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _transition_scene(body) -> void:
	await white_noise.begin_transition_animation().timeout()
	white_noise.end_transition_animation()
