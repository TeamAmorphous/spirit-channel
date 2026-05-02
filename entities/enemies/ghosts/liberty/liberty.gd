extends Ghost

@export var shades_droppable: PackedScene
@export var shades_spawnpoint: Node2D


@onready var shades_anim: Sprite2D = %Shades
var has_shades: bool = true


func _ready() -> void:
	shades_anim.visible = false


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


func _get_shades() -> void:
	has_shades = true
	const IDLE_ANIM := &"idle"
	$StateMachine/Chase.animation = IDLE_ANIM
	$StateMachine/Idle.animation = IDLE_ANIM 


func _on_flashed(from: Node2D) -> void:
	super._on_flashed(from)
	if has_shades:
		_drop_shades()
