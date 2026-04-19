class_name Ghost
extends Enemy


@onready var debug_label: Label = $DebugLabel

@onready var frequency: FrequencyComponent = $FrequencyComponent

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var contact_damage_area: Area2D = $AttackArea

@export var decel: float = 200.0

@export var light_resist_time: float = 5.0
@export var light_resist_cooldown_time: float = 2.0

var facing: Vector2


@onready var light_resist: float = light_resist_time
@onready var light_resist_cooldown: float = light_resist_cooldown_time
@onready var original_sprite_scale: Vector2 = sprite.scale

func _ready():
	debug_label.visible = OS.is_debug_build() 


func _process(delta: float) -> void:
	if OS.is_debug_build():
		var debug_string: String = ""
		debug_string += "State: %s\n" % state_machine.get_state_path_name()
		debug_string += "LR: %f\n" % light_resist
		debug_string += "LRCD: %f\n" % light_resist_cooldown
		debug_label.text = debug_string

	sprite.modulate = Color.WHITE + (Color.WHITE * 5.0 * ((light_resist_time - light_resist) / light_resist_time))

	if light_resist_cooldown > 0:
		light_resist_cooldown -= delta
		if light_resist_cooldown < 0:
			light_resist_cooldown = 0
	else:
		light_resist += delta * 2
		if light_resist >= light_resist_time:
			light_resist = light_resist_time

	var facing_left := facing.x < 0

	sprite.scale.x = lerpf(
		sprite.scale.x,
		(-1 if facing_left else 1) * original_sprite_scale.x,
		10.0 * delta
	)


func _physics_process(_delta: float) -> void:
	move_and_slide()


func on_caught_in_flashlight(delta: float, damage_amount: int = 1, from: Node = null) -> void:
	light_resist -= delta
	light_resist_cooldown = light_resist_cooldown_time
	if light_resist <= 0:
		light_resist = light_resist_time
		light_resist_cooldown = 0
		damage(damage_amount, from)


func damage(amount: int, from: Node = null) -> void:
	state_machine.change_state("Hurt", {"from"=from})
	health.damage(amount)
