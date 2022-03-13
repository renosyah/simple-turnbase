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
	spawn_entity(Global.mp_game_data["grids"])
	
func spawn_entity(grids : Array):
	_terrain.generated_grid = grids
	_terrain.spawn_grid()
	
############################################################
# terrain
func _on_terrain_on_terrain_ready():
	.player_ready()
	
func _on_terrain_on_finish_generate(_generated_grid):
	pass
	
func _on_terrain_on_grid_click(_node):
	pass
	
func _on_terrain_on_spawning_grid(task_done, max_task):
	_ui.display_loading_progress("Generating Map...", task_done, max_task)
	
############################################################
# unit
func _on_unit_on_click(_unit : Unit):
	pass
	
############################################################
# player
func players_updated():
	.players_updated()
	if not .is_all_player_ready():
		_ui.display_loading_progress("Waiting players...", .count_player_ready(), players.size())
		return
		
	_ui.display_loading(false)

















