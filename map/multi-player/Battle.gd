extends Node
class_name BattleMP

const PLAYER_STATUS_NOT_READY = 0
const PLAYER_STATUS_READY = 1

const GAME_LOADING = 0
const GAME_START = 1
const GAME_INFO = 2
const GAME_OVER = 3
const GAME_FINISH = 4

################################################################
# client and server variables
var selected_unit : Unit

################################################################
# server variables
var game_flag = GAME_LOADING
var turn = 0
var players = []

################################################################

func _ready():
	game_flag = GAME_LOADING
	get_joined_players()
	add_audio_player()
#	get_tree().set_quit_on_go_back(false)
#	get_tree().set_auto_accept_quit(false)

################################################################
# network connection watcher
# for both client and host
func init_connection_watcher():
	Network.connect("server_disconnected", self , "_server_disconnected")
	Network.connect("connection_closed", self , "_connection_closed")
	
	# if some player decide or happen to be disconect
	Network.connect("player_disconnected", self, "_on_player_disconnected")
	Network.connect("receive_player_info", self,"_on_receive_player_info")
	
func _on_player_disconnected(_player_network_unique_id : int):
	Network.request_player_info(_player_network_unique_id)
	
func _on_receive_player_info(_player_network_unique_id : int, data : Dictionary):
	on_player_disynchronize(data["name"])
	
func _server_disconnected():
	on_host_disconnected()
	
func _connection_closed():
	print("exit by Client!")
	
func on_player_disynchronize(_player_name : String):
	pass
	
func on_host_disconnected():
	pass

func is_server():
	if not is_network_on():
		return false
		
	if not get_tree().is_network_server():
		return false
		
	return true
	
func is_network_on() -> bool:
	if not get_tree().network_peer:
		return false
		
	if get_tree().network_peer.get_connection_status() == NetworkedMultiplayerPeer.CONNECTION_DISCONNECTED:
		return false
		
	return true
	
################################################################
 # player
func get_joined_players():
	for player in Global.mp_players:
		var data = {
			"id" : player["id"],
			"turn" : player["turn"],
			"name" : player["name"],
			"flag_status" : PLAYER_STATUS_NOT_READY
		}
		if player.has("is_bot") and player["is_bot"]:
			data["is_bot"] = true
			data["flag_status"] = PLAYER_STATUS_READY
			
		players.append(data)
		
func player_ready():
	var data = {
		"id" : Global.player_data.id,
		"flag_status" : PLAYER_STATUS_READY
	}
	rpc("_update_player_joined", data)
	
remotesync func _update_player_joined(data : Dictionary):
	for player in players:
		if player["id"] == data["id"]:
			update_dictionary(player, data) 
			break
			
	players_updated(is_all_player_ready())
	
	
func players_updated(_is_all_ready : bool):
	if not _is_all_ready:
		return
		
	game_flag = GAME_START
	
func update_dictionary(dic, update : Dictionary):
	for key in dic.keys():
		if update.has(key):
			dic[key] = update[key]
		
func count_player_ready() -> int:
	var num = 0
	for i in players:
		if i["flag_status"] == PLAYER_STATUS_READY:
			num += 1
	return num
	
func is_all_player_ready() -> bool:
	if players.empty():
		return false
		
	for i in players:
		if i["flag_status"] == PLAYER_STATUS_NOT_READY:
			return false
		
	return true
	

################################################################
 # turn
func next_turn():
	if is_server():
		_next_turn()
		
	else:
		rpc_id(Network.PLAYER_HOST_ID,"_next_turn")
	
remote func _next_turn():
	if not is_server():
		return
		
	turn += 1
	if turn > players.size() - 1:
		turn = 0
		
		
	rpc("_on_change_turn", turn)
	
remotesync func _on_change_turn(_turn : int):
	if not is_server():
		turn = _turn
		
	on_change_turn()
	
func on_change_turn():
	pass
	
func is_my_turn(_player_id : String) -> bool:
	for i in players:
		if i["id"] == _player_id and i["turn"] == turn:
			return true
			
	return false
	
################################################################
 # unit
func generate_units(_terrain_path : NodePath, _quantity : int = 1) -> Array:
	var units = []
		
	var _terrain_node = get_node_or_null(_terrain_path)
	if not is_instance_valid(_terrain_node):
		return units
		
	var _walkable_grids = []
	for i in _terrain_node.get_grids():
		if i.is_walkable:
			_walkable_grids.append(i)
			
	for player in players:
		for i in _quantity:
			var model = Monsters.MODELS[randi() % Monsters.MODELS.size()]
			var _grid = _walkable_grids[randi() %  _walkable_grids.size()]
			var _unit_data = {}
			_unit_data["name"] = "Unit-" + str(i) + "-" + player["id"]
			_unit_data["network_master"] = Network.PLAYER_HOST_ID
			_unit_data["skin_texture"] = model["skin_texture"]
			_unit_data["mesh_model"] = model["mesh_model"]
			_unit_data["max_ap"] = int(rand_range(1, 3))
			_unit_data["max_hp"] = int(rand_range(5, 10))
			_unit_data["attack_damage"] = int(rand_range(2, 3))
			#_unit_data["color"] = Color.white
			_unit_data["team"] = player["id"]
			_unit_data["translation"] = _grid.translation
			_unit_data["grid"] = _grid.get_path()
			_unit_data["player"] = player
			units.append(_unit_data)
			
			_walkable_grids.erase(_grid)
		
	return units
	
remotesync func _spawn_units(_unit_holder_path : NodePath, _units : Array):
	for  data in _units:
		spawn_unit(_unit_holder_path, data)
		
func spawn_unit(_unit_holder_path : NodePath, _unit_data : Dictionary):
	var _unit_holder = get_node_or_null(_unit_holder_path)
	if not is_instance_valid(_unit_holder):
		return
		
	var unit = preload("res://scene/unit/monster/monster.tscn").instance()
	unit.name = _unit_data["name"]
	unit.set_network_master(_unit_data["network_master"])
	unit.skin_texture = _unit_data["skin_texture"]
	unit.mesh_model = _unit_data["mesh_model"]
	unit.color = (Color.green if _unit_data["team"] == Global.player_data.id else Color.red) #_unit_data["color"]
	unit.team = _unit_data["team"]
	unit.max_ap = _unit_data["max_ap"]
	unit.ap = unit.max_ap
	unit.max_hp = _unit_data["max_hp"]
	unit.hp = unit.max_hp
	unit.attack_damage = _unit_data["attack_damage"]
	unit.player = _unit_data["player"]
	
	unit.connect("on_click", self ,"_on_unit_on_click")
	unit.connect("on_attack_performed", self, "_on_unit_attack_performed")
	unit.connect("on_dead", self ,"_on_unit_dead")
	unit.connect("on_waypoint_reach", self, "_on_unit_waypoint_reach")
	_unit_holder.add_child(unit)
	
	unit.translation = _unit_data["translation"]
	unit.rotate_y(rand_range(-180, 180))
	unit.current_grid = get_node(_unit_data["grid"])
	unit.current_grid.occupier = unit
	
	
func _on_unit_attack_performed(_unit):
	#_unit.reset_unit()
	pass
	
func _on_unit_waypoint_reach(_unit):
	#_unit.reset_unit()
	pass
	
func _on_unit_dead(_unit : Unit):
	if _unit.is_current_grid_valid():
		_unit.current_grid.occupier = null
	_unit.queue_free()
	
func count_movable_unit(_unit_holder_path : NodePath, _player_id : String) -> bool:
	var count = 0
	var _unit_holder = get_node_or_null(_unit_holder_path)
	if not is_instance_valid(_unit_holder):
		return count
		
	for i in _unit_holder.get_children():
		if i.team == _player_id and i.ap > 0:
			count += 1
		
	return count
	
func get_all_unit(_unit_holder_path : NodePath, _player_id : String) -> Array:
	var units = []
	
	var _unit_holder = get_node_or_null(_unit_holder_path)
	if not is_instance_valid(_unit_holder):
		return units
		
	for i in _unit_holder.get_children():
		if i.team == _player_id:
			units.append(i)
			
	return units
	
var _cycle_movable_unit_pos = 0
func cycle_movable_unit(_unit_holder_path : NodePath, _player_id : String) -> Unit:
	var units = []
	
	var _unit_holder = get_node_or_null(_unit_holder_path)
	if not is_instance_valid(_unit_holder):
		return null
		
	for i in _unit_holder.get_children():
		if i.team == _player_id and i.ap > 0:
			units.append(i)
			
	if units.empty():
		return null
		
	_cycle_movable_unit_pos += 1
	if _cycle_movable_unit_pos > units.size() - 1:
		_cycle_movable_unit_pos = 0
		
	return units[_cycle_movable_unit_pos]

################################################################
 # unit movement
func move_unit(_unit : Unit, _terrain : Spatial, from, to : Vector2):
	if is_server():
		_move_unit(
			_unit.get_path(),
			_terrain.get_path(),
			from, to
		)
		
	else:
		rpc_id(Network.PLAYER_HOST_ID,"_move_unit",
			_unit.get_path(),
			_terrain.get_path(),
			from, to
		)
		
func attack_unit(_from_unit, _to_unit : Unit):
	if is_server():
		_attack_unit(_from_unit.get_path(), _to_unit.get_path())
	else:
		rpc_id(Network.PLAYER_HOST_ID,"_attack_unit", _from_unit.get_path(), _to_unit.get_path())
		
remote func _move_unit(_unit_path : NodePath, _terrain_path : NodePath, from, to : Vector2):
	var _unit = get_node_or_null(_unit_path )
	if not is_instance_valid(_unit):
		return
		
	var _terrain = get_node_or_null(_terrain_path)
	if not is_instance_valid(_terrain):
		return
		
	var waypoints = _terrain.get_list_grid_path(from, to)
	_unit.set_waypoints(waypoints)
	
	
remote func _attack_unit(_from_unit_path, _to_unit_path : NodePath):
	var _from_unit = get_node_or_null(_from_unit_path)
	if not is_instance_valid(_from_unit):
		return
		
	_from_unit.perform_attack(_to_unit_path)
	
############################################################
# unit and grid selection
func is_player_own_unit(_unit : Unit) -> bool:
	return _unit.team == Global.player_data.id
	
func is_this_currently_selected_unit(_unit : Unit) -> bool:
	return _unit == selected_unit
	
func is_selected_unit_valid() -> bool:
	return is_instance_valid(selected_unit) and selected_unit.ap > 0
	
func is_grid_is_highlight(_unit : Unit) -> bool:
	return _unit.current_grid.is_highlight()
	
func clear_highlight(_terrain : Spatial):
	for i in _terrain.get_grids():
		i.highlight(false)
		
		
func highlight_adjacent_grid(_terrain : Spatial, _unit : Unit):
	var grids_in_range = []
	var enemy_in_range = []
	
	if _unit.ap == 0:
		return
		
		# check if any enemy near attack range
	for i in _unit.current_grid.get_adjacent_neighbors(_unit.attack_range, false):
		if i.is_walkable:
			if is_instance_valid(i.occupier):
				if i.occupier.is_enemy(_unit.team):
					enemy_in_range.append(i)
					continue
			else:
				grids_in_range.append(i)
				
	if enemy_in_range.size() > 0:
		for i in grids_in_range:
			i.highlight(true, Color.white)
			
		for i in enemy_in_range:
			i.highlight(true, Color.red)
			
		return
		
	# no enemy, change travel mode
	for i in _unit.current_grid.get_adjacent_neighbors(_unit.ap, true):
		if i.is_walkable and not is_instance_valid(i.occupier):
			i.highlight(true, Color.white)
	
	
############################################################
# sound
var audio_sfx : AudioStreamPlayer

func add_audio_player():
	audio_sfx = AudioStreamPlayer.new()
	audio_sfx.bus = "sfx"
	add_child(audio_sfx)
	
func play_audio_click():
	audio_sfx.stream = preload("res://assets/sound/click.wav")
	audio_sfx.play()
	
func play_audio_unit_selected():
	audio_sfx.stream = preload("res://assets/sound/selection_click.wav")
	audio_sfx.play()
	
func play_audio_unit_attacking():
	audio_sfx.stream = preload("res://assets/sound/bubble_cling.wav")
	audio_sfx.play()
	
func play_audio_unit_move():
	audio_sfx.stream = preload("res://assets/sound/move_click.wav")
	audio_sfx.play()
	
func play_audio_invalid_click():
	audio_sfx.stream = preload("res://assets/sound/wrong_click.wav")
	audio_sfx.play()









































