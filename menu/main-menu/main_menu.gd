extends Node

onready var _terrain = $terrain

# Called when the node enters the scene tree for the first time.
func _ready():
	_terrain.size = 2
	_terrain.map_seed = randi()
	_terrain.density = rand_range(0.25, 0.55)
	_terrain.generate()
	_terrain.spawn_grid()
