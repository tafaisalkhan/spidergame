extends Node

const SAVE_PATH := "user://spider_wars_progress.cfg"
const BACKGROUND_MUSIC = preload("res://assets/sound/backgroud.mp3")

var music_enabled := true
var sfx_enabled := true
var music_player: AudioStreamPlayer

func _ready() -> void:
	if not OS.get_cmdline_args().has("--script"):
		var save := ConfigFile.new()
		if save.load(SAVE_PATH) == OK:
			music_enabled = bool(save.get_value("settings", "music", true))
			sfx_enabled = bool(save.get_value("settings", "sfx", true))
	music_player = AudioStreamPlayer.new()
	music_player.name = "BackgroundMusic"
	var soundtrack := BACKGROUND_MUSIC.duplicate() as AudioStreamMP3
	soundtrack.loop = true
	music_player.stream = soundtrack
	music_player.volume_db = -21.0
	add_child(music_player)
	if music_enabled:
		music_player.play()

func set_music_enabled(value: bool) -> void:
	music_enabled = value
	if is_instance_valid(music_player):
		if value and not music_player.playing:
			music_player.play()
		music_player.stream_paused = not value
	save_settings()
	get_node("/root/SignalHub").music_changed.emit(music_enabled)

func set_sfx_enabled(value: bool) -> void:
	sfx_enabled = value
	save_settings()
	get_node("/root/SignalHub").sfx_changed.emit(sfx_enabled)

func save_settings() -> void:
	if OS.get_cmdline_args().has("--script"):
		return
	var save := ConfigFile.new()
	save.load(SAVE_PATH)
	save.set_value("settings", "music", music_enabled)
	save.set_value("settings", "sfx", sfx_enabled)
	save.save(SAVE_PATH)
