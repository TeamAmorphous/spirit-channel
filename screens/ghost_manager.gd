extends Node

const FURNITURE_GROUP := &"furniture"

@export var rat_chance: float = 0.25
@export var rat_king_chance: float = 0.10

@export var random_ghost_spawns: Node

@export var player: Player

var last_furniture: Furniture

@export var rat_scene: PackedScene
@export var rat_king_scene: PackedScene
@export var pages_spawn_green: int = 0
var green_enabled := false
var green_active := false

@export var red_scene: PackedScene
@export var pages_spawn_red: int = 3
@export var red_spawn: Node2D
var red_enabled := false
var red_active := false

@export var blue_scene: PackedScene
@export var pages_spawn_blue: int = 6
@export var blue_spawn: Node2D
var blue_enabled := false
var blue_active := false

@export var yellow_scene: PackedScene
@export var pages_spawn_yellow: int = 7
@export var yellow_spawn: Node2D
var yellow_enabled := false
var yellow_active := false
var random_spawn_positions: Array[Vector2]

@export var spawn_cooldown_min: float = 30.0
@export var spawn_cooldown_max: float = 90.0

var spawn_timer: Timer

func _ready() -> void:
	player.item_recieved.connect(_on_item_added_or_removed)
	player.item_lost.connect(_on_item_added_or_removed)
	await get_tree().process_frame
	check_pages()
	populate_spawns()

	var all_furniture: Array[Furniture]
	all_furniture.assign(get_tree().get_nodes_in_group(FURNITURE_GROUP))

	for f in all_furniture:
		f.interacted_with.connect(try_spawn_rat.bind(f).unbind(1))

	spawn_timer = Timer.new()
	spawn_timer.autostart = false
	spawn_timer.timeout.connect(func():
		spawn_timer.start(randf_range(spawn_cooldown_min, spawn_cooldown_max))
		try_spawn_random_page_ghost.call_deferred()
	)
	spawn_timer.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(spawn_timer)
	spawn_timer.start(randf_range(spawn_cooldown_min, spawn_cooldown_max))


func populate_spawns() -> void:
	if random_ghost_spawns:
		var spawn_nodes: Array[Node2D]
		spawn_nodes.assign(random_ghost_spawns.get_children().filter(func(n: Node): return n is Node2D))
		random_spawn_positions.assign(spawn_nodes.map(func(n: Node2D): return n.global_position))


func _on_item_added_or_removed(item: StringName) -> void:
	if item == &"page":
		check_pages()


func check_pages() -> void:
	var page_count := player.item_count(&"page")

	var old_red := red_enabled
	var old_blue := blue_enabled
	var old_yellow := yellow_enabled
	
	green_enabled = page_count >= pages_spawn_green
	red_enabled = page_count >= pages_spawn_red
	blue_enabled = page_count >= pages_spawn_blue
	yellow_enabled = page_count >= pages_spawn_yellow

	if red_enabled and not old_red and not red_active:
		try_spawn_ghost(
			red_scene,
			get_spawn_pos(red_spawn)
		).tree_exiting.connect(func():
			red_active = false
		)
		red_active = true
	if blue_enabled and not old_blue and not blue_active:
		try_spawn_ghost(
			blue_scene,
			get_spawn_pos(blue_spawn)
		).tree_exiting.connect(func():
			blue_active = false
		)
		blue_active = true
	if yellow_enabled and not old_yellow and not yellow_active:
		try_spawn_ghost(
			yellow_scene,
			get_spawn_pos(yellow_spawn)
		).tree_exiting.connect(func():
			yellow_active = false
		)
		yellow_active = true


func try_spawn_random_page_ghost() -> bool:
	var available: Array[StringName]
	if red_enabled and not red_active: available.append(&"red")
	if blue_enabled and not blue_active: available.append(&"blue")
	if yellow_enabled and not yellow_active: available.append(&"yellow")

	if not available:
		return false
	
	match available.pick_random():
		&"red":
			try_spawn_ghost(
				red_scene,
				get_spawn_pos(red_spawn)
			).tree_exiting.connect(func():
				red_active = false
			)
			red_active = true
		&"blue":
			try_spawn_ghost(
				blue_scene,
				get_spawn_pos(blue_spawn)
			).tree_exiting.connect(func():
				blue_active = false
			)
			blue_active = true
		&"yellow":
			try_spawn_ghost(
				yellow_scene,
				get_spawn_pos(yellow_spawn)
			).tree_exiting.connect(func():
				yellow_active = false
			)
			yellow_active = true
	return true



func try_spawn_rat(furniture: Furniture) -> void:
	# if furniture is not empty, don't spawn anything
	if furniture.contains:
		return
	
	# don't allow spawns on the same piece of furniture twice in a row
	if last_furniture == furniture:
		return
	last_furniture = furniture
	
	if green_enabled and randf() < rat_king_chance and not green_active:
		try_spawn_ghost(
			rat_king_scene,
			furniture.global_position + Vector2(0, -200),
			Vector2(randf_range(-800.0, 800.0), -randf_range(300.0, 500.0))
		).tree_exiting.connect(func():
			green_active = false
		)
		green_active = true
	elif randf() < rat_chance:
		try_spawn_ghost(
			rat_scene,
			furniture.global_position + Vector2(0, -200),
			Vector2(randf_range(-800.0, 800.0), -randf_range(300.0, 500.0))
		)


func try_spawn_ghost(ghost_scene: PackedScene, position: Vector2, velocity: Vector2 = Vector2.ZERO) -> Ghost:
	if not ghost_scene or not ghost_scene.can_instantiate():
		return null
	var ghost := ghost_scene.instantiate() as Ghost
	ghost.global_position = position
	ghost.velocity = velocity
	SceneManager.current_scene.add_child(ghost)
	if not ghost.velocity.is_zero_approx():
		# 'Fling' if there's a spawn velocity
		ghost.state_machine.change_state(ghost.state_machine.get_node("Hurt"))
	return ghost


func get_spawn_pos(spawn: Node2D) -> Vector2:
	if not spawn or get_viewport().get_visible_rect().has_point(spawn.global_position):
		return get_random_offscreen_position()
	return spawn.global_position


func get_random_offscreen_position() -> Vector2:
	if not random_spawn_positions:
		return Vector2.ZERO
	var sorted_farthest: Array[Vector2]
	sorted_farthest.assign(random_spawn_positions)
	var player_pos := player.global_position
	sorted_farthest.sort_custom(func(a: Vector2, b: Vector2): return a.distance_squared_to(player_pos) > b.distance_squared_to(player_pos))
	var vis_rect := get_viewport().get_visible_rect()
	while sorted_farthest:
		var pos: Vector2 = sorted_farthest.pop_front()
		if not vis_rect.has_point(pos):
			return pos
	push_error("No valid offscreen point found in spawn positions.")
	return Vector2.ZERO
