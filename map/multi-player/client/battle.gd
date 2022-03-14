extends BattleMP

onready var _unit_holder = $unit_holder
onready var _spawn_delay = $spawn_delay
onready var _terrain = $terrain
onready var _ui = $ui

# Called when the node enters the scene tree for the first time.
func _ready():
	init_client()
	
############################################################
# client
func init_client():
	_ui.display_loading(true)
	generate_terrain()
	
############################################################
# terrain
func generate_terrain():
	_on_terrain_on_finish_generate(Global.mp_game_data["grids"])
	
func _on_terrain_on_terrain_ready():
	.player_ready()
	
func _on_terrain_on_finish_generate(_generated_grid : Array):
	_terrain.generated_grid = _generated_grid
	_terrain.spawn_grid()
	
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
		
	if .clear_selected_unit(_terrain):
		return
	
############################################################
# unit
func _on_unit_on_click(_unit : Unit):
	if .clear_selected_unit(_terrain):
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

















