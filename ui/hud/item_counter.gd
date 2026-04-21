class_name ItemCounter
extends HBoxContainer


@export var texture: Texture2D
@export var item_name: StringName

var player: Player

func _ready() -> void:
	player = get_tree().get_nodes_in_group(Player.PLAYER_GROUP).pop_front()

	if player:
		player.item_recieved.connect(_on_item_receieved)
		player.item_lost.connect(_on_item_lost)


func _on_item_receieved(item: StringName) -> void:
	if item == item_name:
		var icon := TextureRect.new()
		icon.texture = texture
		icon.custom_minimum_size = Vector2.ONE * 10.0
		icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.scale = Vector2.ONE * 0.5
		add_child(icon)


func _on_item_lost(item: StringName) -> void:
	if item != item_name:
		return
	
	if get_child_count() > 0:
		var child: Node = get_child(0) 
		child.queue_free()
		remove_child(child)
