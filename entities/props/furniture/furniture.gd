class_name Furniture
extends Node2D

signal interacted_with(player: Player)

@export var contains: PackedScene
@export var shake_length: float = 1.0
@export var shake_intensity: float = 10.0
@export var shake_sound: AudioStream

@onready var interactable: Interactable = $Interactable
@onready var sprite: Node2D = $Sprite
@onready var sound_player: AudioStreamPlayer = $AudioStreamPlayer

var sprite_mat: ShaderMaterial

var shake_timer := 0.0


func _ready() -> void:
	sprite_mat = sprite.material.duplicate() # Copy from inherited
	sprite.material = sprite_mat
	if shake_sound:
		sound_player.stream = shake_sound


func _process(delta: float) -> void:
	if shake_timer > 0.0:
		shake_timer -= delta
		sprite.position = Vector2(randf() - 0.5, randf() - 0.5) * 2.0 * shake_intensity
	else:
		shake_timer = 0.0
		sprite.position = Vector2.ZERO


func shake() -> void:
	if shake_timer > 0:
		return
	shake_timer = shake_length
	sound_player.play()


func _on_interacted_with(player: Player) -> void:
	interacted_with.emit(player)
	shake()
	if contains and contains.can_instantiate():
		var item = contains.instantiate() as Node2D
		item.global_position = player.global_position + Vector2(0, -100)
		if item is Pickup:
			item.apply_impulse(Vector2(1000.0 * [-1, 1].pick_random(), randf_range(-2000.0, -1000.0)))
		SceneManager.current_scene.add_child(item)
	contains = null


func get_spawn_position() -> Vector2:
	return $SpawnPosition.global_position if has_node("SpawnPosition") else global_position


func _on_player_cannot_interact() -> void:
	sprite_mat.set_shader_parameter("width", 0.0)


func _on_player_can_interact() -> void:
	sprite_mat.set_shader_parameter("width", 10.0)
