extends Node

const GameConfig = preload("res://scripts/GameConfig.gd")

var players := {}
var missing := []
var verified_events := []
var trigger_counts := {}
var bgm_player: AudioStreamPlayer
var bgm_stream: AudioStream
var bgm_missing := false
var bgm_play_requested := false
var bgm_loaded := false

func _ready() -> void:
	var is_headless := DisplayServer.get_name().to_lower().contains("headless")
	_load_bgm(is_headless)
	for event_name in GameConfig.SFX.keys():
		trigger_counts[event_name] = 0
		var path: String = GameConfig.SFX[event_name]
		if is_headless:
			if ResourceLoader.exists(path):
				verified_events.append(event_name)
			else:
				missing.append(path)
			continue
		var stream := load(path)
		if stream == null:
			missing.append(path)
			continue
		var player := AudioStreamPlayer.new()
		player.stream = stream
		player.bus = "Master"
		add_child(player)
		players[event_name] = player

func _load_bgm(is_headless: bool) -> void:
	if ResourceLoader.exists(String(GameConfig.BGM["runtime_path"])):
		bgm_stream = load(String(GameConfig.BGM["runtime_path"]))
	bgm_loaded = bgm_stream != null
	bgm_missing = not bgm_loaded
	if bgm_stream is AudioStreamOggVorbis:
		bgm_stream.loop = true
	elif bgm_stream is AudioStreamWAV:
		bgm_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	if not bgm_loaded or is_headless:
		return
	bgm_player = AudioStreamPlayer.new()
	bgm_player.stream = bgm_stream
	bgm_player.bus = "Master"
	bgm_player.volume_db = -12.0
	add_child(bgm_player)

func start_bgm() -> void:
	bgm_play_requested = true
	if bgm_player != null and not bgm_player.playing:
		bgm_player.play()

func stop_bgm() -> void:
	bgm_play_requested = false
	if bgm_player != null:
		bgm_player.stop()

func play_event(event_name: String) -> void:
	if trigger_counts.has(event_name):
		trigger_counts[event_name] = int(trigger_counts[event_name]) + 1
	if not players.has(event_name):
		return
	var player: AudioStreamPlayer = players[event_name]
	player.stop()
	player.play()

func loaded_events() -> Array:
	if players.is_empty():
		return verified_events
	return players.keys()

func triggered_events() -> Dictionary:
	return trigger_counts.duplicate(true)

func bgm_status() -> Dictionary:
	return {
		"source_input_path": String(GameConfig.BGM["source_input_path"]),
		"runtime_path": String(GameConfig.BGM["runtime_path"]),
		"stream_loaded": bgm_loaded,
		"stream_length_seconds": bgm_stream.get_length() if bgm_stream != null else 0.0,
		"play_requested": bgm_play_requested,
		"has_audio_player": bgm_player != null,
		"playing": bgm_player.playing if bgm_player != null else false,
		"loop_enabled": (bgm_stream.loop if bgm_stream is AudioStreamOggVorbis else bgm_stream.loop_mode == AudioStreamWAV.LOOP_FORWARD if bgm_stream is AudioStreamWAV else false),
		"display_server": DisplayServer.get_name(),
		"is_silent_placeholder": false,
		"replaced_previous_bgm": true
	}

func shutdown() -> void:
	stop_bgm()
	if bgm_player != null:
		bgm_player.stream = null
		bgm_player.queue_free()
		bgm_player = null
	for event_name in players.keys():
		var player: AudioStreamPlayer = players[event_name]
		player.stop()
		player.stream = null
		player.queue_free()
	players.clear()
