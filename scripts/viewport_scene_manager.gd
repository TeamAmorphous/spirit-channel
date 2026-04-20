class_name ViewportSceneManager
extends Node

@export var scene_container: Node

var current_scene: Node

func _ready() -> void:
	if not scene_container:
		push_error("ViewportSceneManager scene_container is not set!")
		queue_free()
		return

	SceneManager.scene_manager = self

	if scene_container.get_child_count() > 0:
		current_scene = scene_container.get_child(0)


func change_scene_packed(scene: PackedScene) -> int:
	if not scene or not scene.can_instantiate():
		return Error.ERR_CANT_CREATE
	
	if current_scene:
		current_scene.queue_free()
	
	current_scene = scene.instantiate()
	scene_container.add_child(current_scene)
	return Error.OK


func change_scene(scene_path: String) -> int:
	var scene := load(scene_path) as PackedScene

	if not scene:
		return Error.ERR_CANT_OPEN
	
	return change_scene_packed(scene)
