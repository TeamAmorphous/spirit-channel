class_name Enemy
extends CharacterBody2D

@onready var health: HealthComponent = $HealthComponent
@onready var state_machine: StateMachine = $StateMachine


func damage(amount: int) -> void:
	health.damage(amount)