extends Control

@export var menu_scene: PackedScene

@onready var mansion_clear_text: RichTextLabel = %MansionClear
@onready var scroll_container: Control = $Scrolling
@onready var credits: RichTextLabel = %Credits

func _ready() -> void:
	if not MusicManager.is_playing():
		MusicManager.start_win()
	mansion_clear_text.visible_ratio = 0.0
	await get_tree().create_timer(1.0).timeout
	var text_tween := get_tree().create_tween()
	text_tween.tween_property(mansion_clear_text, "visible_ratio", 1.0, 0.5)
	await text_tween.finished
	await get_tree().create_timer(0.5).timeout
	var time_left_in_song := MusicManager.get_time_left_in_current_song()
	var credits_tween := get_tree().create_tween()
	credits_tween.tween_property(scroll_container, "position:y", -credits.size.y - size.y, time_left_in_song)
	await credits_tween.finished
	await get_tree().create_timer(1.0).timeout
	SceneManager.change_scene_packed(menu_scene)


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed(&"primary_action"):
		MusicManager.stop()
		SceneManager.change_scene_packed(menu_scene)