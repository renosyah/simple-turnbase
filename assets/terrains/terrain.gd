extends Spatial
class_name Terrain

############################################################
# signals
signal on_terrain_ready
signal on_finish_generate(_generated_grid)
signal on_spawning_grid(task_done, max_task)
signal on_grid_click(_node)

############################################################
# variables
const GRIDS_BASE = {
	0 : "",
	1 : "res://assets/terrains/model/Base.obj",
	2 : "res://assets/terrains/model/coast.obj",
	3 : "res://assets/terrains/model/ocean.obj"
}
const GRIDS_TOP = {
	0 : "",
	1 : "res://assets/terrains/model/lava_vent.obj",
	2 : "res://assets/terrains/model/desert_mountain.obj",
	3 : "res://assets/terrains/model/mountain.obj",
	4 : "res://assets/terrains/model/hill.obj",
	5 : "res://assets/terrains/model/volcano.obj",
	6 : "res://assets/terrains/model/Forest.obj",
	7 : "res://assets/terrains/model/jungle_forest.obj",
	8 : "res://assets/terrains/model/jungle_tree.obj",
	9 : "res://assets/terrains/model/Ore_Deposit.obj",
	10 :"res://assets/terrains/model/Ore_1.obj",
	11 : "res://assets/terrains/model/Ore_2.obj",
	12 : "res://assets/terrains/model/iceberg.obj",
	13 : "res://assets/terrains/model/tree.obj"
}
const TILE_SIZE := 1.0
const HEX_TILE = preload("res://assets/terrains/grid/grid.tscn")

var HexGrid = preload("res://addons/Hex/HexGrid.gd").new()

onready var _holder = $Spatial
onready var _delay = $delay

export (int, 2, 16) var size := 8
export (float, 0.1, 0.9) var density := 0.3
export (int) var map_seed = 123456

var generated_grid = []

############################################################
# Called when the node enters the scene tree for the first time.
# override methods
func _ready() -> void:
	HexGrid.hex_scale = Vector2(1.18, 1.18) #Vector2(1.15, 1.15)
	
############################################################
# function
func generate():
	generated_grid.clear()
	
	var simplex = OpenSimplexNoise.new()
	simplex.seed = map_seed
	simplex.octaves = 4
	simplex.period = 15
	simplex.lacunarity = 1.5
	simplex.persistence = 0.75

	var points = Utils.draw_hexagon_points(size)
	for i in points:
		if i["type"] == 1:
			var tile_coordinates := Vector2.ZERO
			tile_coordinates.x = (i["vector"]["x"] - size) * TILE_SIZE * cos(deg2rad(30))
			tile_coordinates.y = (i["vector"]["y"] - size) * TILE_SIZE * cos(deg2rad(30))
			
			var axial_coordinate = HexGrid.get_hex_at(tile_coordinates).axial_coords
			axial_coordinate.y = int(axial_coordinate.y) + 0.0
			axial_coordinate.x = int(axial_coordinate.x) + 0.0
			
			var base_key = _get_base_grid_key(simplex.get_noise_2d(tile_coordinates.x, tile_coordinates.y))
			var top_key = _get_grid_top_key(base_key)
			var grid = {
				"is_walkable" : _check_is_walkable(base_key, top_key),
				"mesh_top" : GRIDS_TOP[top_key],
				"mesh_base" : GRIDS_BASE[base_key],
				"translation" : HexGrid.get_hex_center3(axial_coordinate),
				"axial_coordinate" : axial_coordinate,
			}
			
			if not is_in_array(grid,generated_grid):
				generated_grid.append(grid)
		
	emit_signal("on_finish_generate", generated_grid)
	
func is_in_array(obj : Dictionary, arr : Array) -> bool:
	for i in arr:
		if i["axial_coordinate"] == obj["axial_coordinate"]:
			return true
			
	return false
	
func spawn_grid():
	clear_terrain()
	
	if generated_grid.empty():
		return
		
	HexGrid.set_bounds(
		generated_grid[0]["axial_coordinate"],
		generated_grid[generated_grid.size() - 1]["axial_coordinate"]
	)
	
	generated_grid.shuffle()
	
	var created_grid = 0
	for grid in generated_grid:
		var tile = HEX_TILE.instance()
		tile.is_walkable = grid["is_walkable"]
		tile.mesh_top = grid["mesh_top"]
		tile.mesh_base = grid["mesh_base"]
		tile.axial_coordinate = grid["axial_coordinate"]
		tile.connect("on_click", self, "_on_click")
		HexGrid.add_obstacles(tile.axial_coordinate, 1)
		
		_delay.start()
		yield(_delay, "timeout")
		
		_holder.add_child(tile)
		tile.translate(grid["translation"])
			
		created_grid += 1
		emit_signal("on_spawning_grid", created_grid, generated_grid.size())
		
	
	emit_signal("on_terrain_ready")
	
	
func clear_terrain():
	for i in _holder.get_children():
		_holder.remove_child(i)
		
	for i in HexGrid.get_obstacles():
		HexGrid.remove_obstacles(i)
	
	
func get_grids() -> Array:
	return _holder.get_children()
	
	
func _on_click(_node):
	emit_signal("on_grid_click", _node)
	
	
func get_adjacent_neighbors(from : HexGrid, _range : int = 1, _only_travel : bool = true) -> Array:
	var adjacent_neighbors = []
	for i in preload("res://addons/Hex/HexCell.gd").new(from.axial_coordinate).get_all_within(_range):
		var _path = NodePath(str(_holder.get_path()) + "/" + Utils.create_grid_name(i.axial_coords))
		var _node = get_node_or_null(_path)
		if not is_instance_valid(_node):
			continue
			
		if _only_travel:
			if not is_instance_valid(_node.occupier):
				adjacent_neighbors.append(_node)
			
		else:
			adjacent_neighbors.append(_node)
	
	return adjacent_neighbors
	
	
func get_list_grid_path(from, to : HexGrid) -> Array:
	var exceptions = []
	for i in _holder.get_children():
		if not i.is_walkable or is_instance_valid(i.occupier):
			exceptions.append(i.axial_coordinate)
		
	var hex_grid_paths = HexGrid.find_path(from.axial_coordinate, to.axial_coordinate, exceptions)
		
	var path = []
	for i in hex_grid_paths:
		var ac = i.axial_coords
		if ac == from.axial_coordinate:
			continue
			
		var _node = get_node_or_null(str(_holder.get_path()) + "/" + Utils.create_grid_name(ac))
		if is_instance_valid(_node):
			path.append(_node)
		
	return path
	
	
func _get_base_grid_key(_noice_sample : float) -> int:
	if _noice_sample < 0.0:
		return 1
	elif _noice_sample > 1.0 and _noice_sample < 0.2:
		return 2
	elif _noice_sample > 0.2 and _noice_sample < 0.3:
		return 3
	elif _noice_sample > 0.3 and _noice_sample < 0.6:
		return 3
		
	return 1
	
	
	
func _get_grid_top_key(base_key : int) -> int:
	if randf() > density:
		return 0
		
	match base_key:
		1:
			var keys = [7,3,5,7,8,8,9,13]
			return keys[randi() % keys.size()]
		2:
			var keys = [0, 0, 9, 0, 0]
			return keys[randi() % keys.size()]
		3:
			var keys = [0, 0, 12, 0, 12, 0, 0, 0]
			return keys[randi() % keys.size()]
			
	return 0
	
	
	
func _check_is_walkable(base_key : int, top_key : int) -> bool:
	if base_key in [0,3]:
		return false
		
	if top_key in [3,5,7,12]:
		return false
		
	return true












