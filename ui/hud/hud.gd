class_name HUD
extends CanvasLayer

@export var player: Player
@export var pages: Array[Texture2D]

@onready var logo_anim_player: AnimationPlayer = $Logo/AnimationPlayer
@onready var page_anim_player: AnimationPlayer = $UI/PagePlayer
@onready var page_display: TextureRect = $UI/PageDisplay

@onready var health_bar: OSDProgressBar = %HealthBar

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


func _process(_delta: float) -> void:
	if randf() < 0.001 and not logo_anim_player.is_playing():
		logo_anim_player.play(&"default", 0.25)


func _on_player_max_health_changed(max_health: int, _old: int) -> void:
	health_bar.max_value = max_health


func _on_player_health_changed(health: int, _old: int) -> void:
	health_bar.value = health


func _on_player_item_recieved(item: StringName) -> void:
	if item == &"keys":
		%KeysCounter.text = "KEYS:\n%d" % player.item_count(&"keys")
	elif item == &"page":
		show_page(player.item_count(&"page") - 1)


func _on_player_item_lost(item: StringName) -> void:
	if item == &"keys":
		var count := player.item_count(&"keys") 
		%KeysCounter.text = ("KEYS:\n%d" % count) if count > 0 else ""


func show_page(n: int) -> void:
	if n >= pages.size():
		return

	_page_request_id += 1
	var request_id := _page_request_id
	page_display.texture = pages[n]
	%PagesCounter.text = "PAGES:\n%d" % (n + 1)
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
