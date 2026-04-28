# AutoLoad: MusicManager
extends Node

const BASE_TRACK: AudioStreamOggVorbis = preload("uid://sa1ymnucvveu")
const GHOST_TRACKS: Dictionary[Ghost.Channel, AudioStreamOggVorbis] = {
	Ghost.Channel.RED: preload("uid://c3e13ui7v3olf"),
	Ghost.Channel.GREEN: preload("uid://frjw5webp0y8"),
	Ghost.Channel.YELLOW: preload("uid://ce7jx8udw2m6k"),
	Ghost.Channel.BLUE: preload("uid://b3offadp4kk77"),
}

@onready var general: AudioStreamPlayer = $General

@onready var base: AudioStreamPlayer = $Base
@onready var ghost_players: Dictionary[Ghost.Channel, AudioStreamPlayer] = {
	Ghost.Channel.RED: $Red,
	Ghost.Channel.GREEN: $Green,
	Ghost.Channel.YELLOW: $Yellow,
	Ghost.Channel.BLUE: $Blue,
}

const MENU_TRACK: AudioStreamOggVorbis = preload("uid://dny8wl3vpjisv")

var current_channel: Ghost.Channel = Ghost.Channel.NONE

func _ready() -> void:
	base.stream = BASE_TRACK
	base.stream.loop = true

	for channel in ghost_players:
		var player := ghost_players[channel]
		player.stream = GHOST_TRACKS.get(channel)
		player.stream.loop = true
		player.volume_db = -80.0


func _process(delta: float) -> void:
	for channel in ghost_players:
		var player := ghost_players[channel]
		var target_db = 0.0 if channel == current_channel else -80.0
		player.volume_db = lerp(player.volume_db, target_db, delta * 20.0)


func snap_volume() -> void:
	for channel in ghost_players:
		var player := ghost_players[channel]
		var target_db = 0.0 if channel == current_channel else -80.0
		player.volume_db = target_db


func start() -> void:
	stop()
	
	base.stream = BASE_TRACK
	base.stream.loop = true

	base.play()
	for channel in ghost_players:
		var player := ghost_players[channel]
		player.stream = GHOST_TRACKS.get(channel)
		player.stream.loop = true
		player.volume_db = -80.0
		player.play()
	
	await get_tree().process_frame
	_sync_all()


func stop() -> void:
	general.stop()
	base.stop()
	for channel in ghost_players:
		var player := ghost_players[channel]
		player.stop()


func _sync_all() -> void:
	var pos := base.get_playback_position() + AudioServer.get_time_since_last_mix()

	for player in ghost_players.values():
		player.seek(pos)


func start_menu():
	general.stream = MENU_TRACK
	general.stream.loop = true
	current_channel = Ghost.Channel.NONE
	snap_volume()
	general.play()

