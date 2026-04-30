class_name HUD
extends CanvasLayer

@export var item_tex_rect: PackedScene = preload("uid://sixa6uqk76s2")

@export var key_textures: Dictionary[StringName, Texture2D] = {
	key = preload("uid://bw8i86xgxvex0"),
	key_red = preload("uid://bsnx7u6s5pxa6"),
	key_green = preload("uid://c5fsxfg8k6p0l"),
	key_blue = preload("uid://c8qg57dnyibgp"),
	key_yellow = preload("uid://dg0lb260qqbvo"),
}

@export var player: Player
@export var pages: Array[Texture2D]

@onready var logo_anim_player: AnimationPlayer = $Logo/AnimationPlayer
@onready var page_anim_player: AnimationPlayer = $UI/PagePlayer
@onready var page_display: TextureRect = $UI/PageDisplay

@onready var health_bar: OSDProgressBar = %HealthBar
@onready var standard_keys: HBoxContainer = %StandardKeys
@onready var color_keys: HBoxContainer = %ColorKeys

var showing_page: bool = false
var _page_request_id := 0

func _ready() -> void:
	if player:
		health_bar.max_value = player.health.max_health
		health_bar.value = player.health.health
		player.health.max_health_changed.connect(_on_player_max_health_changed)
		player.health.health_changed.connect(_on_player_health_changed)
		player.item_recieved.connect(_on_player_item_recieved)
		player.item_lost.connect(_on_player_item_lost)
	update_item_displays()


func _process(_delta: float) -> void:
	if randf() < 0.001 and not logo_anim_player.is_playing():
		logo_anim_player.play(&"default", 0.25)


func _on_player_max_health_changed(max_health: int, _old: int) -> void:
	health_bar.max_value = max_health


func _on_player_health_changed(health: int, _old: int) -> void:
	health_bar.value = health


func _on_player_item_recieved(item: StringName) -> void:
	if item == &"page":
		show_page(player.item_count(&"page") - 1)
	update_item_displays()


func _on_player_item_lost(_item: StringName) -> void:
	update_item_displays()

func update_item_displays() -> void:
	%PagesCounter.text = "PAGES:\n%d" % player.item_count(&"page")
	if item_tex_rect:
		var key_count := player.item_count(&"key")
		var key_counter_children: Array[Node] = %StandardKeys.get_children()
		var shown_key_count := key_counter_children.size()
		while key_count != shown_key_count:
			if key_count > shown_key_count:
				# add key
				var key_rect: TextureRect = item_tex_rect.instantiate()
				key_rect.texture = key_textures.get(&"key")
				%StandardKeys.add_child(key_rect)
				shown_key_count += 1
			else:
				# remove key
				%StandardKeys.remove_child(key_counter_children.pop_front())
				shown_key_count -= 1
		for n in %ColorKeys.get_children():
			n.queue_free()
			%ColorKeys.remove_child(n)
		for color_key in player.get_color_keys():
			var key_rect: TextureRect = item_tex_rect.instantiate()
			key_rect.texture = key_textures.get(color_key)
			%ColorKeys.add_child(key_rect)




func show_page(n: int) -> void:
	if n >= pages.size():
		return

	_page_request_id += 1
	var request_id := _page_request_id
	page_display.texture = pages[n]
	
	player.state_machine.change_state(player.state_machine.get_node("Cutscene"))
	get_tree().paused = true
	await get_tree().create_timer(0.2).timeout
	if request_id != _page_request_id:
		return
	page_anim_player.play(&"show")
	showing_page = true


func close_page() -> void:
	if not showing_page:
		return

	showing_page = false
	_page_request_id += 1
	page_anim_player.play_backwards(&"show")
	await get_tree().create_timer(0.2).timeout
	get_tree().paused = false
	player.state_machine.change_state(player.state_machine.get_node("Idle"))


func _on_page_display_gui_input(event: InputEvent) -> void:
	if not showing_page:
		return

	var mouse_button := event as InputEventMouseButton
	if mouse_button and mouse_button.pressed and mouse_button.button_index == MOUSE_BUTTON_LEFT:
		get_viewport().set_input_as_handled()
		await close_page()


func is_page_open() -> bool:
	return showing_page
