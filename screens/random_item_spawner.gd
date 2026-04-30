extends Node

const FURNITURE_GROUP := &"furniture"


@export var item_scene: PackedScene
@export_range(0.0, 1.0, 0.05) var spawn_chance: float

func _ready() -> void:
	if not item_scene:
		queue_free()
		return
	
	var furniture: Array[Furniture]
	furniture.assign(get_tree().get_nodes_in_group(FURNITURE_GROUP))
	
	for f in furniture:
		f.interacted_with.connect(_on_furniture_interacted_with.bind(f))

func _on_furniture_interacted_with(player: Player, f: Furniture) -> void:
	if f.contains:
		return
	if randf() <= spawn_chance:
		spawn_pickup_at(player)


func spawn_pickup_at(player: Player) -> void:
	if item_scene and item_scene.can_instantiate():
		var item = item_scene.instantiate() as Node2D
		item.global_position = player.global_position + Vector2(0, -100)
		if item is Pickup:
			item.apply_impulse(Vector2(1000.0 * [-1, 1].pick_random(), randf_range(-2000.0, -1000.0)))
		SceneManager.current_scene.add_child(item)