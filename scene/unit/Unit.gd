extends KinematicBody
class_name Unit

############################################################
# signals
signal on_ready(_unit)
signal on_waypoint_reach(_unit)
signal on_click(_unit)
signal on_dead(_unit)
signal on_take_damage(_unit, _hit_by, _damage, _hp, _max_hp)
signal on_pay_action(_unit, _cost, _ap, _max_ap)
signal on_attack_performed(_unit)

############################################################
# variables
const NONE = 1
const IDDLE = 1
const MOVING = 2

# tag
var player = {}
var type_unit = ""
var team : String = ""
var color : Color = Color.white
var hit_by : NodePath

# waypoint
var current_grid : StaticBody
var waypoint_grid : StaticBody
var waypoint_grids = []

# mobility
var velocity = Vector3.ZERO
var moving_state : int = IDDLE
var gravity = 75.0
var speed = 2.0
var turning_speed = 6.0
var offset_distance = 0.25

# firepower
var attack_damage : int = 1
var attack_range : int = 1

# action point
var ap : int = 2
var max_ap : int = 2

# vitality
var is_dead = false
var hp : int = 10
var max_hp :int = 10

# misc
onready var latency = Network.LATENCY
onready var latency_delay = Network.LATENCY_DELAY

var _tween_movement : Tween = null
var _network_timmer : Timer = null
var _input_detection

############################################################
# multiplayer func
func _network_timmer_timeout():
	if is_dead:
		return
		
	if is_master():
		rset_unreliable("_puppet_translation", translation)
		rset_unreliable("_puppet_moving_state", moving_state)
		rset_unreliable("_puppet_rotation", rotation)
		rset_unreliable("_puppet_ap_hp", {"hp" : hp, "ap" : ap})
	
	
puppet var _puppet_translation :Vector3 setget _set_puppet_translation
func _set_puppet_translation(_val :Vector3):
	_puppet_translation = _val
	
	if is_dead:
		return
	
	if is_master():
		return
		
	_tween_movement.interpolate_property(self,"translation", translation, _puppet_translation,latency)
	_tween_movement.start()
	
	
puppet var _puppet_rotation: Vector3 setget _set_puppet_rotation
func _set_puppet_rotation(_val:Vector3):
	_puppet_rotation = _val
	
	
puppet var _puppet_ap_hp : Dictionary setget _set_puppet_ap_hp
func _set_puppet_ap_hp(_val : Dictionary):
	_puppet_ap_hp = _val
	
	if is_master():
		return
		
	ap = _puppet_ap_hp["ap"]
	hp = _puppet_ap_hp["hp"]
	
puppetsync var _puppet_moving_state : int setget _set_puppet_moving_state
func _set_puppet_moving_state(_val : int):
	_puppet_moving_state = _val
	
	if is_master():
		return
		
	moving_state = _puppet_moving_state
	
	
remotesync func _occupied_grid(_waypoint_grid : NodePath):
	var _waypoint_grid_node = get_node_or_null(_waypoint_grid)
	if not is_instance_valid(_waypoint_grid_node):
		return
		
	current_grid.occupier = null
	current_grid = _waypoint_grid_node
	current_grid.occupier = self
	
	
remotesync func _on_waypoint_reach():
	emit_signal("on_waypoint_reach", self)
	
remotesync func _pay_action(_cost, _master_ap : int):
	emit_signal("on_pay_action", self, _cost, ap, max_ap)
	
remotesync func _take_damage(_damage : int, _hit_by: NodePath):
	hit_by = _hit_by
	emit_signal("on_take_damage", self, hit_by, _damage, hp, max_hp)
	
remotesync func _perform_attack(_to: NodePath):
	if is_dead:
		return
	
remotesync func _dead():
	is_dead = true
	set_process(false)
	
	
############################################################
# Called when the node enters the scene tree for the first time.
# override methods
func _ready():
	set_process(true)
	
	if not _tween_movement:
		_tween_movement = Tween.new()
		add_child(_tween_movement)
		
	if not _input_detection:
		_input_detection = preload("res://assets/other/input_detection/input_detection.tscn").instance()
		_input_detection.connect("any_gesture", self,"_on_any_gesture")
		add_child(_input_detection)
		
	connect("input_event", self, "_on_input_event")
		
	if not is_master():
		return
		
	if not _network_timmer:
		_network_timmer = Timer.new()
		_network_timmer.wait_time = latency_delay
		_network_timmer.connect("timeout", self , "_network_timmer_timeout")
		_network_timmer.autostart = true
		add_child(_network_timmer)
		
	emit_signal("on_ready", self)
	
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	moving(delta)
	
	if is_master():
		master_moving(delta)
	else:
		puppet_moving(delta)
	
############################################################
# function
func master_moving(delta):
	if is_dead:
		return
		
	if not is_instance_valid(waypoint_grid):
		return
		
	var direction = global_transform.origin.direction_to(waypoint_grid.global_transform.origin)
	var distance_to_target = global_transform.origin.distance_to(waypoint_grid.global_transform.origin)
	
	if distance_to_target > offset_distance:
		transform_turning(waypoint_grid.global_transform.origin, delta)
		moving_state = MOVING
		velocity = Vector3(direction.x, 0.0 , direction.z) * speed
		
	else:
		moving_state = IDDLE
		velocity = Vector3.ZERO
		
	velocity = move_and_slide(velocity, Vector3.UP)
	
	if moving_state == IDDLE:
		on_unit_waypoint_reach()
		return
	
	
func moving(_delta):
	if is_dead:
		return
	
	
func is_moving():
	return not waypoint_grids.empty()
	
	
	
func set_waypoints(_waypoint_grids : Array):
	if not waypoint_grids.empty():
		return
		
	if _waypoint_grids.empty():
		return
		
	for i in ap:
		if _waypoint_grids.size() > i:
			waypoint_grids.append(_waypoint_grids[i])
			
	if waypoint_grids.empty():
		return
		
	ap -= 1
	waypoint_grid = waypoint_grids[0]
	set_process(true)
	
	rpc_unreliable("_pay_action", 1, ap)
	
	
func on_unit_waypoint_reach():
	rpc("_occupied_grid", waypoint_grid.get_path())
	
	for i in waypoint_grids:
		if i.name == waypoint_grid.name:
			waypoint_grids.erase(i)
			break
			
	waypoint_grid = null
	set_process(false)
	
	if waypoint_grids.empty():
		moving_state = NONE
		rpc("_on_waypoint_reach")
		return
		
	ap -= 1
	waypoint_grid = waypoint_grids[0]
	set_process(true)
	
	rpc_unreliable("_pay_action", 1, ap)
	
	
func puppet_moving(_delta):
	if is_dead:
		return
	
	
func take_damage(_damage : int, _hit_by: NodePath):
	if not is_master():
		return
		
	hp -= _damage
	hit_by = _hit_by
	
	if is_dead:
		return
		
	if hp < 1:
		dead()
		
	rpc_unreliable("_take_damage", _damage, _hit_by)
	
	
func dead():
	if not is_master():
		return
		
	rpc("_dead")
	
	
func perform_attack(_to: NodePath):
	if not is_master():
		return
		
	var _target = get_node_or_null(_to)
	if not is_instance_valid(_target):
		return
		
	_target.take_damage(attack_damage, get_path())
	
	ap -= 1
	rpc_unreliable("_pay_action", 1, ap)
	rpc_unreliable("_perform_attack", _to)
	
func _on_attack_performed():
	emit_signal("on_attack_performed", self)
	
############################################################
# input
func _on_input_event(camera, event, position, normal, shape_idx):
	if event is InputEventMouseButton and event.is_action_pressed("left_click"):
		on_click()
		
	_input_detection.check_input(event)
	
	
func _on_any_gesture(sig ,event):
	if event is InputEventSingleScreenTap:
		on_click()
	
func on_click():
	emit_signal("on_click", self)
	
############################################################
# utils
func transform_turning(direction, delta):
	direction.y = translation.y
	var new_transform = transform.looking_at(direction, Vector3.UP)
	transform = transform.interpolate_with(new_transform, turning_speed * delta)
	
	
func is_current_grid_valid() -> bool:
	if not current_grid:
		return false
		
	if not is_instance_valid(current_grid):
		return false
		
	return true
	
	
func is_master() -> bool:
	if not get_tree().network_peer:
		return false
		
	if get_tree().network_peer.get_connection_status() == NetworkedMultiplayerPeer.CONNECTION_DISCONNECTED:
		return false
		
	if not is_network_master():
		return false
		
	return true
	
	
func is_enemy(_team) -> bool:
	return team != _team and not is_dead
	
############################################################
# testing & debug stuff
func reset_unit():
	ap = max_ap

