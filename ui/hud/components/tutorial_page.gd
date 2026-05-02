class_name TutorialPage
extends Sprite2D


const TUTORIAL_PAGE_GROUP := &"tutorial_pages"


enum PageState {
	IDLE,
	HOVERED,
	ACTIVE,
}


@onready var _original_pos: Vector2 = global_position
@onready var _original_rot: float = global_rotation 
@onready var _original_scale: Vector2 = global_scale


@export var random_rotation_range: float = 0.1
@export var tween_length: float = 0.2
@export var raise_target: Node2D
@export var hover_offset: Vector2 = Vector2.UP * 100.0

var _tween: Tween


func full_raise() -> void:
	if raise_target:
		tween_to(raise_target.global_position, raise_target.rotation, raise_target.scale)
		z_index = 10


func hover_raise() -> void:
	tween_to(_original_pos + hover_offset, _original_rot + randf_range(-random_rotation_range, random_rotation_range), _original_scale * 1.1)
	z_index = 10


func fall() -> void:
	tween_to(_original_pos, _original_rot + randf_range(-random_rotation_range, random_rotation_range), _original_scale)
	z_index = 0


func tween_to(target_position: Vector2 = _original_pos, target_rotation: float = _original_rot, target_scale: Vector2 = _original_scale) -> void:
	# show full
	if _tween and _tween.is_running():
		_tween.kill()
	_tween = get_tree().create_tween().set_parallel().set_ease(Tween.EASE_IN_OUT).set_pause_mode(Tween.TweenPauseMode.TWEEN_PAUSE_PROCESS)
	_tween.tween_property(self, ^"global_position", target_position, tween_length).from_current()
	_tween.tween_property(self, ^"global_rotation", target_rotation, tween_length).from_current()
	_tween.tween_property(self, ^"global_scale", target_scale, tween_length).from_current()


func set_state(state: PageState) -> void:
	match state:
		PageState.IDLE:
			fall()
		PageState.HOVERED:
			hover_raise()
		PageState.ACTIVE:
			full_raise()