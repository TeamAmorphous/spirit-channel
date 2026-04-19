class_name HealthComponent
extends Node
## A component node that stores a health value and it's maximum.


## Emits when [member max_health] is changed.
signal max_health_changed(new: int, old: int)
## Emits when [member health] is changed.
signal health_changed(new: int, old: int)
## Emits when [member health] is changed positively.
signal healed(amount: int)
## Emits when [member health] is changed negatively.
signal hurt(amount: int)
## Emits when [member health] is set to [code]0[/code].
signal health_depleted


## Maximum health. Is not allowed to go below [code]1[/code].[br]
##
## Emits: [signal max_health_changed][br]
## See: [method _set_max_health], [member health]
@export var max_health: int = 10:
	set = _set_max_health

## Current health. Clamped between [code]0[/code] and [member max_health].[br]
##
## Emits: [signal max_health_changed][br]
## See: [method _set_health], [member max_health]
@onready var health: int = max_health:
	set = _set_health


var ratio: float:
	get:
		return float(health) / float(max_health)
	set(r):
		health = int(roundf(max_health * r))


func _set_max_health(value: int) -> void:
	value = maxi(value, 1)
	if max_health == value:
		return
	var old: int = value
	max_health = value
	max_health_changed.emit(max_health, old)
	health = clampi(health, 0, max_health)


func _set_health(value: int) -> void:
	value = clampi(value, 0, max_health)
	if health == value:
		return
	var old: int = health

	health = value
	health_changed.emit(health, old)

	var delta: int = value - old
	if delta > 0:
		healed.emit(delta)
	else:
		hurt.emit(-delta)

	if health == 0:
		health_depleted.emit()

## Subtracts [param amount] from [member health].[br]
##
## Emits: [signal health_changed], [signal hurt][br]
## See: [method _set_health]
func damage(amount: int) -> int:
	if amount <= 0:
		return 0
	var applied := mini(health, amount)
	health -= applied
	return applied

## Adds [param amount] to [member health].[br]
##
## Emits: [signal health_changed], [signal healed][br]
## See: [method _set_health]
func heal(amount: int) -> int:
	if amount <= 0:
		return 0
	var applied := mini(max_health - health, amount)
	health += applied
	return applied