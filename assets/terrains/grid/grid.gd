extends StaticBody

signal on_click(_node)

const ROTATES = [90, -90, 45, -45, 65, -65]

onready var _highlight = $highlight
onready var _top = $top
onready var _base = $base
onready var _tween = $Tween
onready var _input_detection = $input_detection

var occupier : Unit 

var is_walkable = true
var mesh_top : String = ""
var mesh_base: String = ""
var axial_coordinate : Vector2 = Vector2.ZERO

# Called when the node enters the scene tree for the first time.
func _ready():
	set_process(false)
	name = Utils.create_grid_name(axial_coordinate)
	_base.mesh = load(mesh_base)
	
	if mesh_top == "":
		return
		
	_top.mesh = load(mesh_top)
	
	randomize()
	_top.rotate_y(ROTATES[randi() % ROTATES.size()])
	
	
func get_adjacent_neighbors(_range : int = 1, _only_travel : bool = true) -> Array:
	var adjacent_neighbors = []
	for i in preload("res://addons/Hex/HexCell.gd").new(axial_coordinate).get_all_within(_range):
		var _path = NodePath(str(get_parent().get_path()) + "/" + Utils.create_grid_name(i.axial_coords))
		var _node = get_node_or_null(_path)
		if not is_instance_valid(_node):
			continue
			
		if _only_travel:
			if not is_instance_valid(_node.occupier):
				adjacent_neighbors.append(_node)
			
		else:
			adjacent_neighbors.append(_node)
		
	return adjacent_neighbors
	
func _on_grid_input_event(camera, event, position, normal, shape_idx):
	if event is InputEventMouseButton and event.is_action_pressed("left_click"):
		emit_signal("on_click", self)
		
	_input_detection.check_input(event)
	
	
func _on_input_detection_any_gesture(sig ,event):
	if event is InputEventSingleScreenTap:
		emit_signal("on_click", self)
	
func highlight(show : bool, color : Color = Color.white):
	var material : Material = _highlight.mesh.surface_get_material(0).duplicate()
	material.albedo_color = color
	material.albedo_color.a = 0.4
	_highlight.set_surface_material(0, material)
	_highlight.visible = show
	
func is_highlight() -> bool:
	return _highlight.visible
	
	
func pop_grid():
	_tween.interpolate_property(self,"scale", Vector3.ONE * 0.9, Vector3.ONE, 0.6)
	_tween.interpolate_property(self,"translation:y", -0.2, 0.0, 0.3)
	_tween.start()





















