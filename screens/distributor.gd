extends Node

const NOTE_COUNT = 8

const FURNITURE_GROUP := &"furniture"

@export var page_pickup_scene: PackedScene
@export var rat_scene: PackedScene
@export var rat_king_scene: PackedScene
@export var rat_chance: float = 0.25
@export var rat_king_chance: float = 0.10

@export var player: Player

var last_furniture: Furniture
var rat_king_spawned := false


func _ready() -> void:
	await get_tree().process_frame

	var all_furniture: Array[Furniture]
	all_furniture.assign(get_tree().get_nodes_in_group(FURNITURE_GROUP))

	var empty_furniture: Array[Furniture]
	empty_furniture.assign(all_furniture.filter(func(f) -> bool:
		return f.contains == null
	))

	var furniture_with_pages: Array[Furniture]

	# spawn pages
	var page_count := mini(NOTE_COUNT, empty_furniture.size())
	while page_count > 0 and empty_furniture.size() > 0:
		var f := empty_furniture.pick_random() as Furniture
		if f:
			empty_furniture.erase(f)
			f.contains = page_pickup_scene
			furniture_with_pages.push_back(f)
			page_count -= 1

	for f in all_furniture:
		f.interacted_with.connect(try_spawn_rat.bind(f).unbind(1))

func try_spawn_rat(furniture: Furniture) -> void:
	# if furniture is not empty, don't spawn anything
	if furniture.contains:
		return
	
	# don't allow spawns on the same piece of furniture twice in a row
	if last_furniture == furniture:
		return
	last_furniture = furniture
	
	if randf() < rat_king_chance and not rat_king_spawned:
		var rat_king = rat_king_scene.instantiate() as Ghost
		rat_king.global_position = furniture.global_position + Vector2(0, -200)
		add_sibling(rat_king)
		rat_king.state_machine.change_state(rat_king.state_machine.get_node("Hurt"))
		rat_king.velocity = Vector2(randf_range(-800.0, 800.0), -randf_range(300.0, 500.0))
		rat_king_spawned = true
	elif randf() < rat_chance:
		var rat = rat_scene.instantiate() as Ghost
		rat.global_position = furniture.global_position + Vector2(0, -200)
		add_sibling(rat)
		rat.state_machine.change_state(rat.state_machine.get_node("Hurt"))
		rat.velocity = Vector2(randf_range(-800.0, 800.0), -randf_range(300.0, 500.0))
