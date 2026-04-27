extends Node2D


@onready var path: Path2D = $Path2D
@onready var follower: PathFollow2D = $Path2D/PathFollow2D

var shader_mat: ShaderMaterial


func _ready() -> void:
	shader_mat = material.duplicate()
	material = shader_mat


func stairs_cutscene(player: Player, reverse: bool) -> void:
	player.state_machine.change_state(player.state_machine.get_node("Cutscene"))
	var old_vis_layer = player.visibility_layer
	player.z_index = 200

	shader_mat.set_shader_parameter("width", 0.0)
	follower.progress_ratio = 1.0 if reverse else 0.0
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	await player.walk_to(follower.global_position)
	await get_tree().create_timer(0.2).timeout
	follower.progress_ratio = 0.0 if reverse else 1.0
	await player.walk_to(follower.global_position, 0.75)
	await get_tree().create_timer(0.2).timeout
	get_tree().paused = false
	player.process_mode = Node.PROCESS_MODE_INHERIT

	player.z_index = old_vis_layer
	player.state_machine.change_state(player.state_machine.get_node("Idle"))
	shader_mat.set_shader_parameter("width", 10.0)


func _on_top_floor_interacted_with(player: Player) -> void:
	stairs_cutscene(player, true)


func _on_bottom_floor_interacted_with(player: Player) -> void:
	stairs_cutscene(player, false)



func _on_player_cannot_interact() -> void:
	shader_mat.set_shader_parameter("width", 0.0)


func _on_player_can_interact() -> void:
	shader_mat.set_shader_parameter("width", 10.0)
