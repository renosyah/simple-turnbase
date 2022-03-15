extends Unit

onready var _mesh = $pivot/MeshInstance
onready var _tween = $Tween
onready var _hp_bar = $hpBar
onready var _ap_bar = $message_3d
onready var _state = $AnimationTree.get("parameters/playback")
onready var _audio = $AudioStreamPlayer3D

var is_attacking = false
var skin_texture
var mesh_model

############################################################
# multiplayer func
func _set_puppet_moving_state(_val : int):
	._set_puppet_moving_state(_val)
	if is_dead:
		return
		
	if is_attacking:
		return
		
	match moving_state:
		IDDLE:
			_state.travel("iddle")
		MOVING:
			_state.travel("walking")
		NONE:
			pass
		
func _set_puppet_ap_hp(_val : Dictionary):
	._set_puppet_ap_hp(_val)
	_hp_bar.update_bar(hp, max_hp)
	_ap_bar.set_message(str(ap) + "/" + str(max_ap))
	
remotesync func _pay_action(_cost, _master_ap : int):
	._pay_action(_cost, _master_ap)
	_ap_bar.set_message(str(ap) + "/" + str(max_ap))
	
remotesync func _take_damage(_damage : int, _hit_by: NodePath):
	._take_damage(_damage, _hit_by)
	_hp_bar.update_bar(hp, max_hp)
	_tween.interpolate_property(_mesh,"material/0:albedo_color",Color.red, Color.white, 0.3)
	_tween.start()
	
remotesync func _perform_attack(_to: NodePath):
	._perform_attack(_to)
	is_attacking = true
	_state.travel("attack")
	
remotesync func _dead():
	._dead()
	_state.travel("die")
	
############################################################
# Called when the node enters the scene tree for the first time.
func _ready():
	_hp_bar.update_bar(hp, max_hp)
	_hp_bar.set_hp_bar_color(color)
	_hp_bar.show_label(false)
	
	_ap_bar.set_message(str(ap) + "/" + str(max_ap))
	
	_mesh.mesh = load(mesh_model)
	var material = preload("res://scene/unit/material/monster.tres").duplicate()
	material.albedo_texture = load(skin_texture)
	_mesh.set_surface_material(0, material)
	
func puppet_moving(_delta):
	if is_dead:
		return
		
	rotation.y = lerp_angle(rotation.y, _puppet_rotation.y, _delta * 15.0)
	
func perform_attack(_to: NodePath):
	.perform_attack(_to)
	_tween.interpolate_property(
		self,"transform",transform,
		transform.looking_at(get_node(_to).global_transform.origin, Vector3.UP), 0.4
	)
	_tween.start()
	
func _on_finish_dead():
	emit_signal("on_dead", self)
	
func _on_attack_performed():
	._on_attack_performed()
	is_attacking = false
	
func on_click():
	.on_click()
	_tween.interpolate_property(self,"scale", Vector3.ONE * 1.3, Vector3.ONE, 0.2)
	_tween.interpolate_property(self,"translation:y", 0.2, 0.0, 0.2)
	_tween.start()
	
############################################################
# testing & debug stuff
func reset_unit():
	.reset_unit()
	_ap_bar.set_message(str(ap) + "/" + str(max_ap))

















