class_name Ghost
extends Enemy

const GHOST_GROUP := &"ghosts"


enum Channel {
	RED,
	GREEN,
	YELLOW,
	BLUE,
	NONE = -1,
}

const CHANNEL_COLORS: Dictionary[Channel, Color] = {
	Channel.RED: Color.RED,
	Channel.GREEN: Color.GREEN,
	Channel.YELLOW: Color.YELLOW,
	Channel.BLUE: Color.BLUE,
	Channel.NONE: Color.WHITE,
}


@onready var light_sensitivity: LightSensitiveComponent = $LightSensitiveComponent

@onready var sprite_container: Node2D = $Sprite
@onready var sprite: AnimatedSprite2D = $Sprite/AnimatedSprite2D
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var contact_damage_area: Area2D = $AttackArea

@export var decel: float = 800.0

@export var channel: Channel = Channel.NONE

var facing: Vector2

var shake_intensity: float

var channel_synced: bool = false


func _process(delta: float) -> void:
	sprite.modulate = Color.WHITE + (Color.WHITE * 5.0 * light_sensitivity.ratio)
	shake_intensity = 10.0 * light_sensitivity.ratio

	sprite_container.position = Vector2(
		randf_range(-shake_intensity, shake_intensity),
		randf_range(-shake_intensity, shake_intensity)
	)

	var facing_left := facing.x < 0

	sprite_container.scale.x = lerpf(
		sprite_container.scale.x,
		-1 if facing_left else 1,
		10.0 * delta
	)


func update_channel(player_channel: Channel) -> void:
	channel_synced = player_channel == channel or channel == Channel.NONE


func _physics_process(_delta: float) -> void:
	move_and_slide()


func damage(amount: int, from: Node = null, next_state: StringName = &"") -> void:
	state_machine.change_state("Hurt", {from=from, next=next_state})
	health.damage(amount)


func show_shock() -> void:
	$ShockPopup/AnimationPlayer.play("show")


func _on_light_resistance_depleted(from: Node2D) -> void:
	damage(1, from)


func _on_health_depleted() -> void:
	state_machine.change_state("Poof")