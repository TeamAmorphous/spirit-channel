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
@export var green_key_scene: PackedScene
var green_enabled := false
var green_active := false
var green_key_spawned := false

@export var red_scene: PackedScene
@export var pages_spawn_red: int = 3
@export var red_spawn: Node2D
@export var red_key_scene: PackedScene
var red_enabled := false
var red_active := false
var red_key_spawned := false

@export var blue_scene: PackedScene
@export var pages_spawn_blue: int = 6
@export var blue_spawn: Node2D
@export var blue_key_scene: PackedScene
var blue_enabled := false
var blue_active := false
var blue_key_spawned := false

@export var yellow_scene: PackedScene
@export var pages_spawn_yellow: int = 7
@export var yellow_spawn: Node2D
@export var yellow_key_scene: PackedScene
var yellow_enabled := false
var yellow_active := false
var yellow_key_spawned := false

var random_spawn_positions: Array[Vector2]

@export var spawn_cooldown_min: float = 30.0
@export var spawn_cooldown_max: float = 90.0

var spawn_timer: Timer

func _ready() -> void:
	SignalBus.stop_spawning_ghosts.connect(_on_stop_spawning_ghosts)
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

	var to_spawn: PackedScene = null
	var spawn_pos: Vector2 = Vector2.ZERO
	var on_defeat: Callable = Callable()
	if red_enabled and not old_red and not red_active:
		to_spawn = red_scene
		spawn_pos = get_spawn_pos(red_spawn)
		on_defeat = on_red_defeat
		red_active = true
	if blue_enabled and not old_blue and not blue_active:
		to_spawn = blue_scene
		spawn_pos = get_spawn_pos(blue_spawn)
		on_defeat = on_blue_defeat
		blue_active = true
	if yellow_enabled and not old_yellow and not yellow_active:
		to_spawn = yellow_scene
		spawn_pos = get_spawn_pos(yellow_spawn)
		on_defeat = on_yellow_defeat
		yellow_active = true

	if to_spawn:
		try_spawn_ghost.call_deferred(
			to_spawn,
			spawn_pos,
			Vector2.ZERO,
			on_defeat
		)


func on_red_defeat(ghost: Ghost) -> void:
	red_active = false

	if player.has_item(&"key_red"):
		return
	if not red_key_spawned:
		try_spawn_pickup(
			red_key_scene,
			ghost.global_position,
			func():
				red_key_spawned = false
				)
		red_key_spawned = true

func on_green_defeat(ghost: Ghost) -> void:
	green_active = false

	if player.has_item(&"key_green"):
		return
	if not green_key_spawned:
		try_spawn_pickup(
			green_key_scene,
			ghost.global_position,
			func():
				green_key_spawned = false
				)
		green_key_spawned = true

func on_blue_defeat(ghost: Ghost) -> void:
	blue_active = false

	if player.has_item(&"key_blue"):
		return
	if not blue_key_spawned:
		try_spawn_pickup(
			blue_key_scene,
			ghost.global_position,
			func():
				blue_key_spawned = false
				)
		blue_key_spawned = true

func on_yellow_defeat(ghost: Ghost) -> void:
	yellow_active = false
	
	if player.has_item(&"key_yellow"):
		return
	if not yellow_key_spawned:
		try_spawn_pickup(
			yellow_key_scene,
			ghost.global_position,
			func():
				yellow_key_spawned = false
				)
		yellow_key_spawned = true


func try_spawn_random_page_ghost() -> bool:
	var available: Array[StringName]
	if red_enabled and not red_active: available.append(&"red")
	if blue_enabled and not blue_active: available.append(&"blue")
	if yellow_enabled and not yellow_active: available.append(&"yellow")

	if not available:
		return false
	
	var to_spawn: PackedScene = null
	var spawn_pos: Vector2 = Vector2.ZERO
	var on_defeat: Callable = Callable()

	match available.pick_random():
		&"red":
			to_spawn = red_scene
			spawn_pos = get_spawn_pos(red_spawn)
			on_defeat = on_red_defeat
			red_active = true
		&"blue":
			to_spawn = blue_scene
			spawn_pos = get_spawn_pos(blue_spawn)
			on_defeat = on_blue_defeat
			blue_active = true
		&"yellow":
			to_spawn = yellow_scene
			spawn_pos = get_spawn_pos(yellow_spawn)
			on_defeat = on_yellow_defeat
			yellow_active = true 
	
	if to_spawn:
		try_spawn_ghost.call_deferred(
			to_spawn,
			spawn_pos,
			Vector2.ZERO,
			on_defeat
		)

	return true



func try_spawn_rat(furniture: Furniture) -> void:
	# if furniture is not empty, don't spawn anything
	if furniture.contains:
		return
	
	if spawn_timer.paused:
		return
	
	# don't allow spawns on the same piece of furniture twice in a row
	if last_furniture == furniture:
		return
	last_furniture = furniture
	
	if green_enabled and randf() < rat_king_chance and not green_active:
		try_spawn_ghost.call_deferred(
			rat_king_scene,
			furniture.global_position + Vector2(0, -200),
			Vector2(randf_range(-800.0, 800.0), -randf_range(300.0, 500.0)),
			on_green_defeat
		)
		green_active = true
	elif randf() < rat_chance:
		try_spawn_ghost(
			rat_scene,
			furniture.global_position + Vector2(0, -200),
			Vector2(randf_range(-800.0, 800.0), -randf_range(300.0, 500.0))
		)


func try_spawn_ghost(ghost_scene: PackedScene, position: Vector2, velocity: Vector2 = Vector2.ZERO, on_defeat := Callable()) -> Ghost:
	if not ghost_scene or not ghost_scene.can_instantiate():
		return null
	var ghost := ghost_scene.instantiate() as Ghost
	ghost.global_position = position
	ghost.velocity = velocity
	SceneManager.current_scene.add_child(ghost)
	if not ghost.velocity.is_zero_approx():
		# 'Fling' if there's a spawn velocity
		ghost.state_machine.change_state(ghost.state_machine.get_node("Hurt"))
	if on_defeat.is_valid():
		ghost.tree_exiting.connect(on_defeat.bind(ghost))
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


func try_spawn_pickup(pickup_scene: PackedScene, position: Vector2, on_removed := Callable()) -> void:
	var pickup: Pickup = pickup_scene.instantiate() as Pickup
	if pickup:
		var rand_angle := randf() * TAU
		var rand_dir := Vector2.RIGHT.rotated(rand_angle)
		var parent := get_parent()
		parent.add_sibling.call_deferred(pickup)
		pickup.global_position = position
		pickup.apply_force(rand_dir * 200.0)
		if on_removed.is_valid():
			pickup.tree_exiting.connect(on_removed)


func _on_stop_spawning_ghosts() -> void:
	spawn_timer.stop()
	for g in get_tree().get_nodes_in_group(Ghost.GHOST_GROUP):
		g.process_mode = Node.PROCESS_MODE_ALWAYS
		if g is Ghost:
			g.health.health = 0
