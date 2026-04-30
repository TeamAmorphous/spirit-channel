extends Node2D

@export var game_over_scene: PackedScene
@export var boss_ghosts_scene: PackedScene

@export var menu_scene: PackedScene

@onready var pause_menu: PauseMenu = $PauseMenu
@onready var player: Player = $Player


var boss_node: Node

var win := false
var boss := false

func _ready() -> void:
	player.health.health_depleted.connect(_on_player_health_depleted)


func _on_player_health_depleted() -> void:
	if game_over_scene:
		SceneManager.change_scene_packed(game_over_scene)


func _process(_delta: float) -> void:
	if boss and boss_node:
		var ghost_count: int = 0
		for n in boss_node.get_children():
			if n is Ghost:
				ghost_count += 1
		if not ghost_count:
			MusicManager.fade_out()
			boss_node.queue_free()
			boss_node = null
			# game won!
			_on_win()


func _on_win() -> void:
	if win:
		return
	win = true
	player.can_jump = false
	player.can_interact = false
	player.can_move = false
	pause_menu.can_pause = false
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	await player.state_machine.wait_for_state(player.state_machine.get_node("Idle"))
	await get_tree().create_timer(0.1).timeout
	player.state_machine.change_state(player.state_machine.get_node("Cutscene"))
	get_tree().paused = true
	await player.walk_to(Vector2(0.0, player.global_position.y), 0.8)
	await get_tree().create_timer(0.1).timeout
	player.movement_anim_player.play(&"relief")
	await player.movement_anim_player.animation_finished
	await get_tree().create_timer(0.5).timeout
	MusicManager.start_win()
	await get_tree().create_timer(2.0).timeout
	player.movement_anim_player.play(&"idle")
	get_tree().paused = false
	await get_tree().create_timer(10.0).timeout
	SceneManager.change_scene_packed(menu_scene)


func _on_boss_trigger_area_body_entered(body: Node2D) -> void:
	if not player.has_item(&"skull"):
		return
	if body != player or boss:
		return
	if boss_ghosts_scene:
		boss = true
		player.state_machine.change_state(player.state_machine.get_node("Cutscene"))
		player.process_mode = Node.PROCESS_MODE_ALWAYS
		get_tree().paused = true
		player.can_jump = true
		player.can_interact = true
		SignalBus.static_interference.emit(0.5)
		await player.walk_to(Vector2.ZERO, 0.8)
		await get_tree().create_timer(0.5).timeout
		SignalBus.static_interference.emit(1.0)
		await get_tree().create_timer(0.2).timeout

		for d in get_tree().get_nodes_in_group(&"doors"):
			if d is Door:
				d.needs_item = &"!LOCKED!"
		boss_node = boss_ghosts_scene.instantiate()
		add_child(boss_node)
		await get_tree().create_timer(0.5).timeout
		MusicManager.start_boss()
		get_tree().paused = false
		player.process_mode = Node.PROCESS_MODE_INHERIT
		player.state_machine.change_state(player.state_machine.get_node("Idle"))
		

