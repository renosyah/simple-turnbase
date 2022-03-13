extends Spatial

signal on_spotted(_node)

onready var _raycast = $north

var spotting_rotation_speed = 0.03
var team = ""
var spotting_range : int setget _set_spotting_range
var enable : bool setget _set_enable

func _set_spotting_range(_val : int):
	spotting_range = _val
	_raycast.cast_to = _raycast.cast_to * spotting_range
	
func _set_enable(_enable):
	enable = _enable
	set_process(enable)
	
func add_exception(_node):
	_raycast.add_exception(_node)
	
func _ready():
	set_process(false)
	
func _process(delta):
	var rot_speed = rad2deg(spotting_rotation_speed)
	rotate_y(rot_speed * delta)
	
	if _raycast.is_colliding():
		var body = _raycast.get_collider()
		if _is_valid_target(body):
			emit_signal("on_spotted", body)
			set_process(false)
			return
			
func _is_valid_target(_body) -> bool:
	if not is_instance_valid(_body):
		return false
		
	if _body is GameplayCamera:
		return false
		
	if _body is StaticBody:
		return false
		
	if not _body.is_targetable(team):
		return false
		
	return true
	
