class_name LightSensitiveComponent
extends Node

const LIGHT_SENSITIVE_LAYER: int = 1 << 3

signal light_received(amount: float, from: Node2D)

signal resistance_depleted(from: Node2D)
signal resistance_restored(from: Node2D)


@export var enabled: bool = true
@export var repeatable: bool = true
@export var resistance: float = 5.0
@export var cooldown: float = 1.0
@export var recovery_rate: float = 1.0

@onready var body: PhysicsBody2D = owner as PhysicsBody2D

@onready var current_resistance: float = resistance
var cooldown_timer: float = 0
var fired: bool = false

var ratio:
	get:
		return (resistance - current_resistance) / resistance
	set(r):
		current_resistance = resistance - (clampf(r, 0, 1) * resistance) 


func _ready() -> void:
	body.collision_layer |= LIGHT_SENSITIVE_LAYER


func _process(delta: float) -> void:
	if not enabled:
		return
	
	if cooldown_timer > 0:
		cooldown_timer -= delta
		if cooldown_timer < 0:
			cooldown_timer = 0
	elif repeatable or not fired:
		current_resistance += recovery_rate * delta
		if current_resistance >= resistance:
			current_resistance = resistance
			resistance_restored.emit()


func reset() -> void:
	cooldown_timer = 0
	current_resistance = resistance


func _light_raycast_check(from: Vector2) -> bool:
	var space_state := body.get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(
		from,
		body.global_position,
		1 | LIGHT_SENSITIVE_LAYER
	)
	query.collide_with_bodies = true
	query.collide_with_areas = false
	var result := space_state.intersect_ray(query)
	if result:
		return result.collider == body
	return false
			 


func receive_light(amount: float, from: Node2D) -> void:
	if amount <= 0 or not enabled:
		return

	if not _light_raycast_check(from.global_position):
		return

	if current_resistance > 0:
		current_resistance -= amount
	
	cooldown_timer = cooldown
	light_received.emit(amount, from)

	if current_resistance <= 0 and not fired:
		current_resistance = 0
		resistance_depleted.emit(from)
		fired = not repeatable
