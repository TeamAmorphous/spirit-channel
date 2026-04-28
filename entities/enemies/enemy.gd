class_name Enemy
extends CharacterBody2D

signal defeated


const DEFEAT_FREE_TIME := 5.0
const WORLD_COLLISION_MASK := 1 << 0

@export var speed: float = 200.0
@export var hurt_duration := 2.0

@onready var health: Health = $Health

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var root: Node2D = $Root
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var blackboard: Blackboard = $BTPlayer.get_blackboard()

var _target_dir: float = 1.0
var _frames_since_facing_update: int = 0
var _is_dead: bool = false
var _moved_this_frame: bool = false


func _ready() -> void:
	health.hurt.connect(_on_hurt)
	health.knockback_applied.connect(apply_knockback)
	health.health_depleted.connect(defeat)
	blackboard.bind_var_to_property(&"speed", self, &"speed")


func _physics_process(delta: float) -> void:
	_post_physics_process.call_deferred(delta)


func _post_physics_process(delta: float) -> void:
	if not _moved_this_frame:
		velocity = velocity.lerp(Vector2.ZERO, 20.0 * delta)
	_moved_this_frame = false


func _process(delta: float) -> void:
	root.scale.x = lerpf(root.scale.x, _target_dir, 10.0 * delta)


func move(delta: float, p_velocity: Vector2) -> void:
	velocity = velocity.lerp(p_velocity, 20.0 * delta)
	move_and_slide()
	_moved_this_frame = true


func update_facing() -> void:
	_frames_since_facing_update += 1
	if _frames_since_facing_update > 3:
		face_dir(velocity.x)


func face_dir(dir: float) -> void:
	if dir > 0.0 and root.scale.x < 0.0:
		_target_dir = 1.0
		_frames_since_facing_update = 0
	elif dir < 0.0 and root.scale.x > 0.0:
		_target_dir= -1.0
		_frames_since_facing_update = 0


func apply_knockback(knockback: Vector2, duration: float = 10) -> void:
	if knockback.is_zero_approx():
		return
	while duration:
		var delta := get_physics_process_delta_time()
		duration -= delta
		move(delta, knockback)
		await get_tree().physics_frame


func get_facing() -> float:
	return signf(root.scale.x)


func _on_hurt(_amount: int) -> void:
	animation_player.play(&"hurt")
	var btplayer := get_node_or_null(^"BTPlayer") as BTPlayer
	if btplayer:
		btplayer.set_active(false)
	var hsm := get_node_or_null(^"LimboHSM") as LimboHSM
	if hsm:
		hsm.set_active(false)
	await get_tree().create_timer(hurt_duration, false, true).timeout
	if btplayer and not _is_dead:
		btplayer.set_active(true)
	if hsm and not _is_dead:
		hsm.set_active(true)


func validate_position(p_position: Vector2) -> bool:
	var space_state := get_world_2d().direct_space_state
	var params := PhysicsPointQueryParameters2D.new()
	params.position = p_position
	params.collision_mask = WORLD_COLLISION_MASK
	var collision := space_state.intersect_point(params)
	return collision.is_empty()


func defeat() -> void:
	if _is_dead:
		return
	defeated.emit()
	_is_dead = true
	root.process_mode = Node.PROCESS_MODE_DISABLED
	animation_player.play(&"defeat")
	collision_shape.set_deferred(&"disabled", true)

	for child in get_children():
		if child is BTPlayer or child is LimboHSM:
			child.set_active(false)
	
	if get_tree():
		await get_tree().create_timer(DEFEAT_FREE_TIME).timeout
		queue_free()


func get_health() -> Health:
	return health
