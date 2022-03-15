extends BattleMP

onready var _camera = $cameraPivot
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
# ui
func _on_ui_deselect_unit():
	.play_audio_click()
	selected_unit = null
	.clear_highlight(_terrain)
	
func _on_ui_find_movable_unit():
	.play_audio_click()
	var count = .count_movable_unit(_unit_holder.get_path(), Global.player_data.id)
	if count <= 0:
		return
		
	var unit = .cycle_movable_unit(_unit_holder.get_path(), Global.player_data.id)
	if not is_instance_valid(unit):
		return
		
	_camera.translation = unit.translation
	
func _on_ui_get_unit_info():
	pass # Replace with function body.
	
	
func _on_ui_skip_turn():
	selected_unit = null
	_ui.display_control(false)
	_ui.display_loading_turn(true)
	.play_audio_click()
	.clear_highlight(_terrain)
	.next_turn()
	
############################################################
# terrain
func generate_terrain():
	randomize()
	_terrain.size = int(rand_range(6, 8)) # Global.mp_players.size() * 2
	_terrain.map_seed = randi()
	_terrain.density = rand_range(0.25, 0.55)
	_terrain.generate()
	
func _on_terrain_on_terrain_ready():
	.player_ready()
	
func _on_terrain_on_finish_generate(_generated_grid : Array):
	_terrain.spawn_grid()
	host_ready(_generated_grid)
	
func _on_terrain_on_spawning_grid(task_done, max_task : int):
	_ui.display_loading_progress("Generating Map...", task_done, max_task)
	
func _on_terrain_on_grid_click(_node : StaticBody):
	if not .is_my_turn(Global.player_data.id):
		.play_audio_click()
		return
		
	if is_instance_valid(selected_unit) and _node.is_highlight():
		if _node.is_walkable:
			.move_unit(
				selected_unit,
				_terrain,
				selected_unit.current_grid.axial_coordinate,
				_node.axial_coordinate
			)
			.play_audio_unit_move()
		
	else:
		.play_audio_click()
		
	selected_unit = null
	_ui.display_selected_unit(false)
	.clear_highlight(_terrain)
	
	
############################################################
# unit
func _on_unit_on_click(_unit : Unit):
	if not .is_my_turn(Global.player_data.id):
		.play_audio_invalid_click()
		return
		
	if .is_player_own_unit(_unit):
		# selection/movement mode
		if .is_this_currently_selected_unit(_unit):
			selected_unit = null
			.clear_highlight(_terrain)
			_ui.display_selected_unit(false)
			
		else:
			selected_unit = _unit
			.clear_highlight(_terrain)
			.highlight_adjacent_grid(_terrain, selected_unit)
			_ui.display_selected_unit(true)
			
		play_audio_unit_selected()
		
	else:
		# attack mode
		if .is_selected_unit_valid() and .is_grid_is_highlight(_unit):
			.attack_unit(selected_unit, _unit)
			.clear_highlight(_terrain)
			selected_unit = null
			_ui.display_selected_unit(false)
			play_audio_unit_attacking()
			
		else:
			play_audio_invalid_click()
	
############################################################
# player status
func players_updated(_is_all_ready : bool):
	.players_updated(_is_all_ready)
	if not _is_all_ready:
		_ui.display_loading_progress("Waiting players...", .count_player_ready(), players.size())
		return
		
	var _is_my_turn = .is_my_turn(Global.player_data.id)
	_ui.display_control(_is_my_turn)
	_ui.display_loading_turn(not _is_my_turn)
	_ui.display_loading(false)
		
	rpc("_spawn_units", _unit_holder.get_path(), .generate_units(_terrain.get_path(), 4))
	
############################################################
# turn
func on_change_turn():
	.on_change_turn()
	var _is_my_turn = .is_my_turn(Global.player_data.id)
	_ui.display_control(_is_my_turn)
	_ui.display_loading_turn(not _is_my_turn)
	
	for unit in _unit_holder.get_children():
		unit.reset_unit()
	

































