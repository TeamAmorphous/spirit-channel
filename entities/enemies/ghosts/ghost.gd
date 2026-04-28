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


@onready var light_sensitivity: LightSensitive = $LightSensitive

@onready var contact_damage_area: Area2D = $AttackArea
## Desired pushback speed. Only applies if [member knockback_enabled] is true.
@export var light_knockback_strength: float = 500.0
@export var light_knockback_duration: float = 1.5

@export var channel: Channel = Channel.NONE

var shake_intensity: float

var channel_synced: bool = false


func _process(delta: float) -> void:
	super._process(delta)

	root.modulate = Color.WHITE + (Color.WHITE * 5.0 * light_sensitivity.ratio)
	shake_intensity = 10.0 * light_sensitivity.ratio

	root.position = Vector2(
		randf_range(-shake_intensity, shake_intensity),
		randf_range(-shake_intensity, shake_intensity)
	)

func update_channel(player_channel: Channel) -> void:
	channel_synced = player_channel == channel or channel == Channel.NONE


func _on_light_resistance_depleted(from: Node2D) -> void:
	health.health -= 1
	var knockback := (from.global_position - global_position).normalized() * light_knockback_strength
	apply_knockback(knockback, light_knockback_duration)
