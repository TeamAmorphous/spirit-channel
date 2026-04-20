# Autoload: SceneManager
extends Node

signal scene_changed

var scene_manager: Node
var current_scene: Node:
	get:
		return get_current_scene()
	set(_n):
		push_error("Cannot set current_scene in SceneManager")


func change_scene_packed(scene: PackedScene) -> int:
	scene_changed.emit()
	if scene_manager and is_instance_valid(scene_manager) and scene_manager.has_method(&"change_scene_packed"):
		scene_changed.emit()
		return scene_manager.change_scene_packed(scene)
	
	return get_tree().change_scene_to_packed(scene)


func change_scene(scene_path: String) -> int:
	if scene_manager and is_instance_valid(scene_manager) and scene_manager.has_method(&"change_scene"):
		scene_changed.emit()
		return scene_manager.change_scene(scene_path)
	scene_changed.emit()
	return get_tree().change_scene_to_file(scene_path)


func get_current_scene() -> Node:
	if scene_manager and "current_scene" in scene_manager:
		return scene_manager.current_scene
	
	return null