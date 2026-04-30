extends Node2D

## List of items to distribute to child [Furniture].
@export var items: Array[PackedScene]


func _ready() -> void:
	if not items:
		return
	
	var furniture: Array[Furniture]

	for n in get_children():
		if n is Furniture:
			if not n.contains:
				furniture.append(n)

	var item_count := items.size()
	var furniture_count := furniture.size()
	var placed_count := 0

	while items and furniture:
		var item: PackedScene = items.pop_front()
		if item:
			var f: Furniture = furniture.pick_random()
			f.contains = item
			placed_count += 1
			furniture.erase(f)
		
	if items:
		push_error("Could not place all items in '{}'. ({} possible furnitures, {}/{} placed)" % [get_path(), furniture_count, placed_count, item_count])
