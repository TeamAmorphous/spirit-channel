extends Node3D


const STATIC_DURATION := 1.5


@export var crt_overlay: ColorRect
@export var transition_blocker: ColorRect
@export var skeleton: Skeleton3D
@export var channel_bone: StringName
@export var scene_bone: StringName
@export var knob_click_sfx: AudioStreamPlayer3D
@export var static_sfx: AudioStreamPlayer3D

var base_rotation: Quaternion
var channel_bone_idx: int
var scene_bone_idx: int
var channel_tween: Tween
var scene_tween: Tween

func _ready() -> void:
	if not skeleton:
		push_error("Skeleton not set!")
		return
	channel_bone_idx = skeleton.find_bone(channel_bone)
	if channel_bone_idx < 0:
		push_error("Cannot find channel_bone '%s'!" % channel_bone)
		return
	scene_bone_idx = skeleton.find_bone(scene_bone)
	if scene_bone_idx < 0:
		push_error("Cannot find scene_bone '%s'!" % scene_bone)
		return
	base_rotation = skeleton.get_bone_pose_rotation(channel_bone_idx)
	SignalBus.channel_changed.connect(_on_channel_changed)
	SceneManager.scene_changed.connect(_on_scene_changed)
	SignalBus.static_interference.connect(_on_static_interference)


func _on_channel_changed(new: Ghost.Channel, _old: Ghost.Channel) -> void:
	if new == Ghost.Channel.NONE:
		return
	if channel_tween:
		channel_tween.kill()
	
	var start := skeleton.get_bone_pose_rotation(channel_bone_idx)
	var target := base_rotation * Quaternion(Vector3.UP, (PI / 2.0) * new)
	channel_tween = get_tree().create_tween().set_trans(Tween.TRANS_CUBIC)
	knob_click_sfx.play()
	channel_tween.tween_method(
		func(t: float):
			var q := start.slerp(target, t)
			skeleton.set_bone_pose_rotation(channel_bone_idx, q),
		0.0,
		1.0,
		0.2
	)


func _on_scene_changed() -> void:
	if scene_tween:
		scene_tween.kill()
	
	var start := skeleton.get_bone_pose_rotation(scene_bone_idx)
	var target := base_rotation * Quaternion(Vector3.UP, randf_range(-PI, PI))
	scene_tween = get_tree().create_tween().set_trans(Tween.TRANS_CUBIC).set_parallel(true).set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	scene_tween.tween_method(
		func(t: float):
			var q := start.slerp(target, t)
			skeleton.set_bone_pose_rotation(scene_bone_idx, q),
		0.0,
		1.0,
		0.2
	)
	var shader_mat : ShaderMaterial = crt_overlay.material as ShaderMaterial
	scene_tween.set_trans(Tween.TRANS_LINEAR)
	get_tree().paused = true
	knob_click_sfx.play()
	static_sfx.play()
	scene_tween.tween_property(static_sfx, "volume_db", -80.0, STATIC_DURATION).from(0.0)
	scene_tween.tween_property(transition_blocker, "color:a", 0.0, STATIC_DURATION).from(1.0)
	scene_tween.tween_method(
		func(n):
			shader_mat.set_shader_parameter("noise_amount", n),
		1.0,
		0.03,
		STATIC_DURATION
	)
	scene_tween.chain().tween_callback(func(): get_tree().paused = false)


func _on_static_interference(amount: float) -> void:
	var shader_mat : ShaderMaterial = crt_overlay.material as ShaderMaterial
	var tween := get_tree().create_tween().set_parallel(true).set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	static_sfx.play()
	tween.tween_method(
		func(n):
			shader_mat.set_shader_parameter("noise_amount", n),
		amount,
		0.03,
		0.5
	)
	tween.tween_property(static_sfx, "volume_db", -80.0, 0.5).from(0.0)