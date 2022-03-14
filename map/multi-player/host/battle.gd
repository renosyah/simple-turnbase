extends BattleMP

onready var _unit_holder = $unit_holder
onready var _spawn_delay = $spawn_delay
onready var _terrain = $terrain
onready var _ui = $ui

func _ready():
	init_host()
	
############################################################
# host
func init_host():
	_ui.display_loading(true)
	generate_terrain()
	
func host_ready(grids : Array):
	Global.rpc("on_host_game_session_ready", {"grids" : grids})
	
############################################################
# terrain
func generate_terrain():
	randomize()
	_terrain.size = int(rand_range(4, 6))
	_terrain.map_seed = randi()
	_terrain.density = rand_range(0.25, 0.55)
	_terrain.generate()
	
func _on_terrain_on_finish_generate(_generated_grid : Array):
	_terrain.spawn_grid()
	host_ready(_generated_grid)
	
func _on_terrain_on_terrain_ready():
	.player_ready()
	
func _on_terrain_on_spawning_grid(task_done, max_task : int):
	_ui.display_loading_progress("Generating Map...", task_done, max_task)
	
func _on_terrain_on_grid_click(_node : StaticBody):
	_node.pop_grid()
	if is_instance_valid(selected_unit) and _node.is_highlight():
		if _node.is_walkable:
			.move_unit(
				selected_unit,
				_terrain,
				selected_unit.current_grid.axial_coordinate,
				_node.axial_coordinate
			)
		
	if .clear_selected_unit():
		return
	
############################################################
# unit
func _on_unit_on_click(_unit : Unit):
	if .clear_selected_unit():
		return
		
	.highlight_near_adjacent_from(_unit)
	
############################################################
# player
func players_updated():
	.players_updated()
	if not .is_all_player_ready():
		_ui.display_loading_progress("Waiting players...", .count_player_ready(), players.size())
		return
		
	_ui.display_loading(false)
	game_flag = GAME_START
	
	rpc("_spawn_units", _unit_holder.get_path(), .generate_units(_terrain.get_path(), 4))
	
############################################################
# bot
var _bot_index = 0

func _on_bot_timeout():
	if game_flag != GAME_START:
		return
		
	if _unit_holder.get_children().empty():
		return
		
	_bot_index += 1
	if _bot_index > _unit_holder.get_child_count() - 1:
		_bot_index = 0
		
	var unit = _unit_holder.get_children()[_bot_index]
	if unit.is_moving():
		return
	
	# attack mode
	if randf() < 0.5:
		var attack_range_grids = unit.current_grid.get_adjacent_neighbors(unit.attack_range, false)
		if attack_range_grids.empty():
			return
			
		for node_in_range in attack_range_grids:
			if is_instance_valid(node_in_range.occupier):
				if node_in_range.occupier != unit:
					unit.perform_attack(node_in_range.occupier.get_path())
					return
		return
		
	# travel mode
	var travel_range_grids = unit.current_grid.get_adjacent_neighbors(unit.travel_distance)
	if travel_range_grids.empty():
		return
		
	var from_grid =  unit.current_grid
	var to_grid = travel_range_grids[randi() % travel_range_grids.size()]
	
	var _waypoint_grids = _terrain.get_list_grid_path(from_grid.axial_coordinate, to_grid.axial_coordinate)
	if _waypoint_grids.empty():
		return
		
	unit.set_waypoints(_waypoint_grids)




































