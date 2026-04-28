class_name Hitbox
extends Area2D
## Area that deals damage

## The damage that this hitbox applies to recipients. Only applies to entities with a [Health] component.
@export var damage: int = 1
## If true, the hitbox will apply a knockback to the recipient. The direction is determined by the position of the recipient relative to the hitbox.
@export var knockback_enabled: bool = false
## Desired pushback speed. Only applies if [member knockback_enabled] is true.
@export var knockback_strength: float = 500.0

func _ready() -> void:
	area_entered.connect(_on_area_entered)


func _on_area_entered(hurtbox: Hurtbox) -> void:
	if hurtbox.owner == owner:
		return
	hurtbox.take_damage(damage, get_knockback(hurtbox), self)


func get_knockback(target: Node2D) -> Vector2:
	var knockback := Vector2.ZERO
	if knockback_enabled:
		knockback = (target.global_position - global_position).normalized() * knockback_strength
	return knockback