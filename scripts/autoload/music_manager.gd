# AutoLoad: MusicManager
extends Node


signal general_finished


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
const BOSS_TRACK: AudioStreamOggVorbis = preload("uid://d0872m2ed47tk")
const WIN_TRACK: AudioStreamOggVorbis = preload("uid://be4ff6ceaxfp8")

var current_channel: Ghost.Channel = Ghost.Channel.NONE
var fading: bool = false

func _ready() -> void:
	general.finished.connect(general_finished.emit)
	base.stream = BASE_TRACK
	base.stream.loop = true

	for channel in ghost_players:
		var player := ghost_players[channel]
		player.stream = GHOST_TRACKS.get(channel)
		player.stream.loop = true
		player.volume_db = -80.0


func _process(delta: float) -> void:
	if fading:
		return
	for channel in ghost_players:
		var player := ghost_players[channel]
		var target_db = 0.0 if channel == current_channel else -80.0
		player.volume_db = lerp(player.volume_db, target_db, delta * 20.0)


func snap_volume() -> void:
	for channel in ghost_players:
		var player := ghost_players[channel]
		var target_db = 0.0 if channel == current_channel else -80.0
		player.volume_db = target_db


func is_playing() -> bool:
	return base.playing or general.playing


func start() -> void:
	stop()
	await get_tree().process_frame
	base.stream = BASE_TRACK
	base.stream.loop = true

	base.volume_db = 0.0
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
	if general.playing and general.stream == MENU_TRACK:
		return
	general.stream = MENU_TRACK
	general.stream.loop = true
	general.volume_db = 0.0
	current_channel = Ghost.Channel.NONE
	snap_volume()
	general.play()


func start_boss():
	if general.playing and general.stream == BOSS_TRACK:
		return
	general.stream = BOSS_TRACK
	general.stream.loop = true
	general.volume_db = 0.0
	current_channel = Ghost.Channel.NONE
	snap_volume()
	general.play()


func start_win():
	if general.playing and general.stream == WIN_TRACK:
		return
	general.stream = WIN_TRACK
	general.stream.loop = false
	general.volume_db = 0.0
	current_channel = Ghost.Channel.NONE
	snap_volume()
	general.play()

func fade_out(time: float = 0.5) -> void:
	fading = true
	var tween := get_tree().create_tween().set_parallel(true).set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(general, "volume_linear", 0.0, time).from_current()
	tween.tween_property(base, "volume_linear", 0.0, time).from_current()
	for channel in ghost_players:
		tween.tween_property(ghost_players[channel], "volume_linear", 0.0, time).from_current()
	await tween.finished
	stop()
	base.volume_db = -80.0
	general.volume_db = -80.0
	for channel in ghost_players:
		ghost_players[channel].volume_db = -80.0
	fading = false


func get_time_left_in_current_song() -> float:
	if general.playing:
		var total_length := general.stream.get_length()
		var curr_pos := general.get_playback_position() + AudioServer.get_time_since_last_mix()
		return total_length - curr_pos
	return 0.0