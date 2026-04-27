class_name Pickup
extends RigidBody2D

const PICKUP_LAYER := 1 << 5
const FLASH_RATE := 0.2


@export var item: StringName
@export var cooldown: float = 1.0
@export var lifetime: float = 10.0

@export var pickup_sound: AudioStream
@export var grabbed_particles: PackedScene

@onready var timer: float = lifetime

func _ready() -> void:
	collision_layer = 0
	get_tree().create_timer(cooldown, false).timeout.connect(func() -> void:
		collision_layer = PICKUP_LAYER
	)

func pickup(player: Player) -> void:
	if grabbed_particles and grabbed_particles.can_instantiate():
		var particles = grabbed_particles.instantiate() as Node2D
		particles.global_position = global_position
		add_sibling(particles)
	if pickup_sound:
		var audio_player = AudioStreamPlayer.new()
		audio_player.stream = pickup_sound
		add_sibling(audio_player)
		audio_player.play()
		audio_player.process_mode = Node.ProcessMode.PROCESS_MODE_ALWAYS
		audio_player.finished.connect(audio_player.queue_free)
	if item:
		player.add_item(item)
	queue_free()


func _process(delta: float) -> void:
	if lifetime >= 0.1:
		timer -= delta
		if timer <= lifetime / 4.0:
			if fmod(timer, FLASH_RATE) < FLASH_RATE / 2:
				modulate = Color(1, 1, 1, 0.5)
			else:
				modulate = Color(1, 1, 1, 1)
		if timer <= 0:
			queue_free()