extends Node

const DEKSTOP =  ["Server", "Windows", "WinRT", "X11"]
const VERSION_SAVE = "1.4"
var PERSISTEN_SAVE = true

func _ready():
	PERSISTEN_SAVE = not OS.get_name() in DEKSTOP
	load_player_data()
	load_audio_setting()
	play_music()
		
################################################################
# play music!
const AUDIO_SAVE_FILE = "audio_setting" + "_" + VERSION_SAVE + ".dat"
var _audio
var audio_setting = { music = false, sfx = true }

func play_music():
	if not _audio:
		_audio = AudioStreamPlayer.new()
		#_audio.volume_db = -20
		_audio.stream = preload("res://assets/sound/music.ogg")
		_audio.bus = "music"
		add_child(_audio)
		
	if audio_setting.music:
		_audio.play()
	else:
		_audio.stop()
		
func save_audio_setting():
	if PERSISTEN_SAVE:
		SaveLoad.save(AUDIO_SAVE_FILE, audio_setting)
	
func load_audio_setting():
	var _audio_setting = null 
	
	if PERSISTEN_SAVE:
		_audio_setting = SaveLoad.load_save(AUDIO_SAVE_FILE)
		
	if not _audio_setting:
		_audio_setting = { music = false, sfx = true }
		
	audio_setting  = _audio_setting 
	save_audio_setting()
	
################################################################
# player data
const PLAYER_DATA_SAVE_FILE = "player" + "_" + VERSION_SAVE + ".dat"
var player_data = {}

func new_player_data() -> Dictionary:
	var _data = {
		id = "PLAYER-" + GDUUID.v4(),
		name = RandomNameGenerator.generate()
	}
	return _data
	
func save_player_data():
	if PERSISTEN_SAVE:
		SaveLoad.save(PLAYER_DATA_SAVE_FILE, player_data)
	
func load_player_data():
	var _player_data = null 
	
	if PERSISTEN_SAVE:
		_player_data = SaveLoad.load_save(PLAYER_DATA_SAVE_FILE)
		
	if not _player_data:
		_player_data = new_player_data()
		
	player_data = _player_data
	save_player_data()

################################################################
# multiplayer connection and data
signal on_host_game_session_ready(_mp_game_data)

remotesync func on_host_game_session_ready(_mp_game_data : Dictionary):
	emit_signal("on_host_game_session_ready", _mp_game_data)

const MODE_HOST = 0
const MODE_JOIN = 1
var mode = MODE_HOST

var server = {
	ip = '127.0.0.1',
	port = 31400,
	max_player = 4,
}
var client = {
	ip = '',
	port = 31400,
	network_unique_id = 0,
}

var mp_players = []
var mp_game_data = {}
var mp_exception_message = ""

################################################################






