extends Ghost

@export var shades_droppable: PackedScene
@export var shades_spawnpoint: Node2D


var has_shades: bool = true



func _process(delta: float) -> void:
	super._process(delta)
	light_sensitivity.can_be_damaged = not has_shades


func _drop_shades() -> void:
	if shades_droppable:
		var shades := shades_droppable.instantiate() as Droppable
		add_sibling(shades)
		shades.global_position = shades_spawnpoint.global_position
		shades.velocity = velocity + Vector2(
			randf_range(200.0, 100.0) * (1 if facing.x < 0 else -1),
			-randf_range(200.0, 500.0)
		)
		shades.scale = shades_spawnpoint.global_scale
		const IDLE_ANIM := &"liberty/no_shades"
		$StateMachine/Chase.animation = IDLE_ANIM
		$StateMachine/Idle.animation = IDLE_ANIM 
	has_shades = false


func _on_flashed(from: Node2D) -> void:
	if has_shades:
		state_machine.change_state("Hurt", {"from"=from})
		_drop_shades()
