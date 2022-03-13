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
# server variables
var game_flag = GAME_LOADING
var players = []

################################################################

func _ready():
	game_flag = GAME_LOADING
	get_joined_players()
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
			"id" : player.id,
			"name" : player.name,
			"flag_status" : PLAYER_STATUS_NOT_READY
		}
		players.append(data)
		
func player_ready():
	var data = {
		"id" : Global.player_data.id,
		"name" :  Global.player_data.name,
		"flag_status" : PLAYER_STATUS_READY
	}
	rpc("_update_player_joined", data)
	
remotesync func _update_player_joined(data : Dictionary):
	for player in players:
		if player["id"] == data["id"]:
			update_dictionary(player, data) 
			break
			
	players_updated()
	
	
func players_updated():
	pass
	
func update_dictionary(dic, update : Dictionary):
	for key in dic.keys():
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
 # unit
remotesync func _spawn_units(_unit_holder_path : NodePath, _units : Array):
	var _unit_holder = get_node_or_null(_unit_holder_path)
	if not is_instance_valid(_unit_holder):
		return
		
	for  data in _units:
		spawn_unit(_unit_holder, data)
		
func generate_units(_terrain_path : NodePath) -> Array:
	var units = []
		
	var _terrain_node = get_node_or_null(_terrain_path)
	if not is_instance_valid(_terrain_node):
		return units
		
	var _walkable_grids = []
	for i in _terrain_node.get_grids():
		if i.is_walkable:
			_walkable_grids.append(i)
		
	for i in 8:
		var model = Monsters.MODELS[randi() % Monsters.MODELS.size()]
		var _grid = _walkable_grids[randi() %  _walkable_grids.size()]
		var _unit_data = {}
		_unit_data["name"] = "Unit-" + str(i)
		_unit_data["network_master"] = Network.PLAYER_HOST_ID
		_unit_data["skin_texture"] = model["skin_texture"]
		_unit_data["mesh_model"] = model["mesh_model"]
		_unit_data["color"] = Color.red
		_unit_data["team"] = "monster"
		_unit_data["translation"] = _grid.translation
		_unit_data["grid"] = _grid.get_path()
		units.append(_unit_data)
		
		_walkable_grids.erase(_grid)
		
	return units
	
func spawn_unit(_unit_holder : Node, _unit_data : Dictionary):
	var unit = preload("res://scene/unit/monster/monster.tscn").instance()
	unit.name = _unit_data["name"]
	unit.set_network_master(_unit_data["network_master"])
	unit.skin_texture = _unit_data["skin_texture"]
	unit.mesh_model = _unit_data["mesh_model"]
	unit.color = _unit_data["color"]
	unit.team = _unit_data["team"]
	unit.is_sync = true
	
	unit.connect("on_click", self ,"_on_unit_on_click")
	unit.connect("on_dead", self ,"_on_unit_dead")
	unit.connect("on_waypoint_reach", self, "_on_unit_waypoint_reach")
	_unit_holder.add_child(unit)
	
	unit.translation = _unit_data["translation"]
	unit.rotate_y(rand_range(-180, 180))
	unit.current_grid = get_node(_unit_data["grid"])
	unit.current_grid.occupier = unit
	
func _on_unit_waypoint_reach(_unit):
	pass
	
func _on_unit_dead(_unit : Unit):
	_unit.current_grid.occupier = null
	_unit.queue_free()
	








































