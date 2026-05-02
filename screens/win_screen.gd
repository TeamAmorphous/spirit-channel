extends Control

@export var menu_scene: PackedScene

@onready var mansion_clear_text: RichTextLabel = %MansionClear
@onready var scroll_container: Control = $Scrolling
@onready var credits: RichTextLabel = %Credits

const CLEAR_TIME_TEXT := "[br][br][font_size=40][wave amp=20.0 freq=2.0]CLEAR TIME[br]%s[/wave][/font_size]"
const BEST_TIME_TEXT := "[br][br][font_size=40][rainbow][shake rate=5.0 level=8][wave amp=20.0 freq=2.0]NEW BEST TIME!!![br]%s[/wave][/shake][/rainbow][/font_size]"


func _ready() -> void:
	if not MusicManager.is_playing():
		MusicManager.start_win()
	
	Settings.save_persistent_data()

	mansion_clear_text.visible_ratio = 0.0
	if Settings.is_new_best_time():
		mansion_clear_text.text += BEST_TIME_TEXT % Settings.get_best_as_string()
	else:
		mansion_clear_text.text += CLEAR_TIME_TEXT % Settings.get_last_clear_as_string()
	
	await get_tree().create_timer(1.0).timeout
	var text_tween := get_tree().create_tween()
	text_tween.tween_property(mansion_clear_text, "visible_ratio", 1.0, 0.5).from(0.0)
	await text_tween.finished
	await get_tree().create_timer(0.5).timeout
	var time_left_in_song := MusicManager.get_time_left_in_current_song()
	var credits_tween := get_tree().create_tween()
	credits_tween.tween_property(scroll_container, "position:y", -credits.size.y - size.y, time_left_in_song)
	await credits_tween.finished
	await get_tree().create_timer(1.0).timeout
	SceneManager.change_scene_packed(menu_scene)


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed(&"primary_action") \
			or Input.is_action_just_pressed(&"ui_accept") \
			or Input.is_action_just_pressed(&"ui_cancel"):
		MusicManager.stop()
		SceneManager.change_scene_packed(menu_scene)