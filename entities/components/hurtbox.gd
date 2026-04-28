class_name Hurtbox
extends Area2D
## Area that receives damage.

@export var health: Health

var last_attack_vector: Vector2 = Vector2.ZERO


func take_damage(amount: int, knockback: Vector2, source: Hitbox) -> void:
	last_attack_vector = owner.global_position - source.owner.global_position
	health.damage(amount, knockback)