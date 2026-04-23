extends Node

const NOTE_COUNT = 8

const FURNITURE_GROUP := &"furniture"

func _ready() -> void:
	await get_tree().process_frame
	var nodes := get_tree().get_nodes_in_group(FURNITURE_GROUP)
	var furniture_with_notes = []
	for i in NOTE_COUNT:
		var node := nodes.pick_random() as Node
		var f := node as Furniture
		while not f:
			nodes.erase(node)
			f = node as Furniture
		f.contains = &"page"
		furniture_with_notes.append(f)
	print(furniture_with_notes)

