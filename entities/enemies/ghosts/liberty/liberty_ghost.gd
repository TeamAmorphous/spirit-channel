extends Ghost

@export var shades_droppable: PackedScene


@onready var shades_spawnpoint: Marker2D = $Sprite/AnimatedSprite2D/ShadesSpawn
var shades: Droppable


func _ready() -> void:
	_spawn_shades()


func _spawn_shades() -> void:
	if shades_droppable:
		shades = shades_droppable.instantiate()
		shades.position = shades_spawnpoint.position
		shades_spawnpoint.get_parent().add_child(shades)
		shades.visible = false


func _process(delta: float) -> void:
	super._process(delta)


func damage(amount: int, from: Node = null) -> void:
	super.damage(amount, from)
	if health.health == 1 and shades:
		shades.visible = true
		var shades_scale := shades.global_scale
		shades.drop(Vector2(
			randf_range(200.0, 100.0) * (1 if facing.x < 0 else -1),
			-randf_range(200.0, 500.0)
		))
		shades.scale = shades_scale
		_spawn_shades()
		idle_anim = &"liberty/no_shades"