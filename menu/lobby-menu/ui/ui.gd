extends Control

const ENABLE_BOT = false

const BUTTON_BATTLE_ENABLE_COLOR = Color(0, 0.592157, 0.035294)
const BUTTON_BATTLE_DISABLE_COLOR = Color(0.27451, 0.27451, 0.27451)

const PLAYER_STATUS_NOT_READY = "NOT_READY"
const PLAYER_STATUS_READY = "READY"

onready var _server_advertise = $server_advertise
onready var _player_holder = $CanvasLayer/control/VBoxContainer/ScrollContainer/VBoxContainer

onready var _scramble_button = $CanvasLayer/control/HBoxContainer/scramble
onready var _play_button = $CanvasLayer/control/HBoxContainer/play
onready var _ready_button = $CanvasLayer/control/HBoxContainer/ready
onready var _add_bot_button_icon = $CanvasLayer/control/VBoxContainer/PanelContainer/HBoxContainer/add_bot/ColorRect2

onready var _exit_timer = $exit_timer
onready var _dialog_exit_option = $CanvasLayer/simple_dialog_option

################################################################
# sync lobby
var player_joined : Array = []

remote func _request_append_player_joined(from : int, data : Dictionary):
	for i in player_joined:
		if i.id == data.id:
			player_joined.erase(i)
			break
			
	data["turn"] = player_joined.size()
	player_joined.append(data)
	rpc("_update_player_joined", player_joined)
	
remote func _request_erase_player_joined(data : Dictionary):
	for i in player_joined:
		if i.id == data.id:
			player_joined.erase(i)
			break
			
	rpc("_update_player_joined", player_joined)
	
remotesync func _update_player_joined(data : Array):
	if is_server():
		_server_advertise.serverInfo["player"] = player_joined.size()
	else:
		player_joined = data
		
	player_joined.sort_custom(MyCustomSorter, "sort")
	fill_player_slot()
	
remotesync func _kick_player(data : Dictionary):
	for i in player_joined:
		if i.id == data.id:
			player_joined.erase(i)
			break
			
	if data.id == Global.player_data.id:
		Network.connect("connection_closed", self , "_got_kickout")
		Network.disconnect_from_server()
		return
		
	fill_player_slot()
	
################################################################
# Called when the node enters the scene tree for the first time.
func _ready():
	_play_button.visible = is_server()
	_play_button.disabled = true
	_play_button.self_modulate = BUTTON_BATTLE_DISABLE_COLOR
	
	_ready_button.visible = not is_server()
	_ready_button.self_modulate = BUTTON_BATTLE_ENABLE_COLOR
	
	_scramble_button.visible = is_server()
	_add_bot_button_icon.visible = ENABLE_BOT
	
	if is_server():
		_init_host()
	else:
		_init_join()
		
	get_tree().set_quit_on_go_back(false)
	get_tree().set_auto_accept_quit(false)
	
func _notification(what):
	match what:
		MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
			_on_back_pressed()
			return
			
		MainLoop.NOTIFICATION_WM_GO_BACK_REQUEST: 
			_on_back_pressed()
			return
			
################################################################
# host player section
func _init_host():
	Network.connect("server_player_connected", self ,"_server_player_connected")
	var err = Network.create_server(Global.server.max_player, Global.server.port,{"name" : Global.player_data.name})
	if err != OK:
		return
	
func _server_player_connected(_player_network_unique_id : int, _player : Dictionary):
	var player = create_mp_player()
	player["status"] = "Ready"
	player["flag"] = PLAYER_STATUS_READY
	_request_append_player_joined(Global.client.network_unique_id,player)
	
	_server_advertise.setup()
	_server_advertise.serverInfo["name"] = Global.player_data.name
	_server_advertise.serverInfo["port"] = Global.server.port
	_server_advertise.serverInfo["public"] = true
	_server_advertise.serverInfo["player"] = player_joined.size()
	_server_advertise.serverInfo["max_player"] = Global.server.max_player
	
################################################################
# join player section
func _init_join():
	Global.connect("on_host_game_session_ready", self, "_on_host_game_session_ready")
	Network.connect("server_disconnected", self , "_server_disconnected")
	Network.connect("client_player_connected", self , "_client_player_connected")
	
	var err = Network.connect_to_server(Global.client.ip, Global.client.port , {"name" : Global.player_data.name})
	if err != OK:
		return
	
func _client_player_connected(_player_network_unique_id : int, player : Dictionary):
	Global.client.network_unique_id = _player_network_unique_id
	rpc_id(Network.PLAYER_HOST_ID, "_request_append_player_joined", Global.client.network_unique_id, create_mp_player())
	
func _on_host_game_session_ready(_mp_game_data : Dictionary):
	Global.mp_game_data = _mp_game_data
	Global.mp_players = player_joined
	get_tree().change_scene("res://map/multi-player/client/battle.tscn")
	
func _server_disconnected():
	Global.mp_exception_message = "Unexpected exit by Server!"
	get_tree().change_scene("res://menu/main-menu/main_menu.tscn")
	
func _got_kickout():
	Global.mp_exception_message = "You have been kickout by host!"
	get_tree().change_scene("res://menu/main-menu/main_menu.tscn")

################################################################
# ui action
func _on_scramble_pressed():
	if not is_server():
		return
		
	if not is_all_player_ready():
		return
		
	var turns = []
	for i in range(0, player_joined.size()):
		turns.append(i)
		
	randomize()
	turns.shuffle()
		
	for i in player_joined:
		var turn = turns[randi() % turns.size()]
		i["turn"] = turn
		turns.erase(turn)
		
	rpc("_update_player_joined", player_joined)
	
func _on_ready_pressed():
	_ready_button.self_modulate = BUTTON_BATTLE_DISABLE_COLOR
	set_player_ready()
	
func _on_play_pressed():
	if not is_server():
		return
		
	if not is_all_player_ready():
		return
		
	Global.mp_players = player_joined
	get_tree().change_scene("res://map/multi-player/host/battle.tscn")
	
func _on_add_bot_pressed():
	if not is_server():
		return
		
	if not ENABLE_BOT:
		return
		
	if player_joined.size() >= Global.server.max_player:
		return
		
	_request_append_player_joined(Network.PLAYER_HOST_ID, create_bot_player())
	
func fill_player_slot():
	for i in _player_holder.get_children():
		_player_holder.remove_child(i)
	
	var is_all_ready = is_all_player_ready()
	_play_button.disabled = (not is_all_ready)
	_play_button.self_modulate = BUTTON_BATTLE_DISABLE_COLOR if (not is_all_ready) else BUTTON_BATTLE_ENABLE_COLOR
	_add_bot_button_icon.visible = ENABLE_BOT and is_server() and player_joined.size() < Global.server.max_player
	
	for i in player_joined:
		var item = preload("res://menu/lobby-menu/ui/item/item.tscn").instance()
		item.data = i
		item.can_kick = (i.id != Global.player_data.id and is_server())
		item.connect("kick", self, "_on_player_get_kick")
		_player_holder.add_child(item)
		
func set_player_ready():
	var data = create_mp_player()
	data.status = "Ready"
	data.flag = PLAYER_STATUS_READY
	
	if not is_server():
		rpc_id(Network.PLAYER_HOST_ID, "_request_append_player_joined", Global.client.network_unique_id,data)
		return
		
	for i in player_joined:
		if i.id == data.id:
			player_joined.erase(i)
			break
		
	player_joined.append(data)
	rpc("_update_player_joined", player_joined)
	
func _on_player_get_kick(_player):
	if not is_server():
		return
		
	rpc("_kick_player", _player)
	
func _on_back_pressed():
	_dialog_exit_option.display_message("Attention!","Are you sure want bac to main menu?")
	_dialog_exit_option.visible = true
	
func _on_simple_dialog_option_on_yes():
	if is_server():
		_on_exit_timer_timeout()
		return
		
	_exit_timer.start()
	rpc("_request_erase_player_joined",{ id = Global.player_data.id })
	
func _on_exit_timer_timeout():
	Network.disconnect_from_server()
	get_tree().change_scene("res://menu/main-menu/main_menu.tscn")
	
################################################################
# utils
func create_mp_player() -> Dictionary:
	return {
		"id" : Global.player_data.id,
		"turn" : 0,
		"name" : Global.player_data.name,
		"status" : "Not Ready",
		"flag" : PLAYER_STATUS_NOT_READY
	}
	
func create_bot_player() -> Dictionary:
	return {
		"id" : "BOT-" + str(GDUUID.v4()),
		"turn" : 0,
		"name" : RandomNameGenerator.generate() + " (Bot)",
		"status" : "Ready",
		"is_bot" : true,
		"flag" : PLAYER_STATUS_READY
	}
	
class MyCustomSorter:
	static func sort(a, b):
		if a["turn"] < b["turn"]:
			return true
		return false
		
func is_server():
	return Global.mode == Global.MODE_HOST
	
func is_all_player_ready() -> bool:
	if player_joined.size() == 1:
		return false
		
	for i in player_joined:
		if i.flag == PLAYER_STATUS_NOT_READY:
			return false
	return true



































