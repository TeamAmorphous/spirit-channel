extends Furniture

@onready var anim_player: AnimationPlayer = $AnimationPlayer

var _opened := false


func _process(_delta: float) -> void:
	if not _opened:
		var player = get_tree().get_nodes_in_group(Player.PLAYER_GROUP).front()
		if player:
			interactable.enabled = player.item_count(&"page") == 8
	else:
		interactable.enabled = false


func _on_interacted_with(player: Player) -> void:
	if not contains or not contains.can_instantiate():
		return

	#interacted_with.emit(player)

	process_mode = Node.PROCESS_MODE_ALWAYS

	interactable.enabled = false
	player.state_machine.change_state(player.state_machine.get_node("Cutscene"))
	sprite_mat.set_shader_parameter("width", 0.0)
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true

	SignalBus.stop_spawning_ghosts.emit()

	MusicManager.fade_out()
	
	await player.walk_to($WalkToPos.global_position, 0.25)
	
	anim_player.play(&"opening")
	await anim_player.animation_finished

	var item = contains.instantiate() as Node2D
	item.global_position = $SpawnPos.global_position
	item.process_mode = Node.PROCESS_MODE_ALWAYS
	if item is Pickup:
		item.apply_impulse(Vector2(100.0 * [-1, 1].pick_random(), -600.0))
	SceneManager.current_scene.add_child(item)

	contains = null
	await get_tree().create_timer(0.5).timeout
	
	get_tree().paused = false
	
	player.process_mode = Node.PROCESS_MODE_INHERIT
	item.process_mode = Node.PROCESS_MODE_INHERIT
	process_mode = Node.PROCESS_MODE_INHERIT
	player.can_jump = false
	player.can_interact = false
	player.state_machine.change_state(player.state_machine.get_node("Idle"))
	sprite_mat.set_shader_parameter.call_deferred("width", 0.0)
