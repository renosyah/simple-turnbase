extends Control

signal find_movable_unit
signal skip_turn
signal get_unit_info
signal deselect_unit

onready var _control = $CanvasLayer/main_ui/control
onready var _selection_mode_layout = $CanvasLayer/main_ui/control/selection_mode_layout
onready var _unit_mode_layout = $CanvasLayer/main_ui/control/unit_mode_layout

onready var _loading = $CanvasLayer/main_ui/loading
onready var _loading_label = $CanvasLayer/main_ui/loading/VBoxContainer/Label
onready var _loading_bar = $CanvasLayer/main_ui/loading/VBoxContainer/loading_bar

onready var _loading_turn = $CanvasLayer/main_ui/loading_turn
onready var _loading_image = $CanvasLayer/main_ui/loading_turn/loading_anim/TextureRect

onready var _game_over = $CanvasLayer/main_ui/game_over
onready var _game_over_condition = $CanvasLayer/main_ui/game_over/VBoxContainer/condition
onready var _game_over_message = $CanvasLayer/main_ui/game_over/VBoxContainer/winner

onready var _dialog_exit_option = $CanvasLayer/main_ui/simple_dialog_option

func _ready():
	_selection_mode_layout.visible = true
	_dialog_exit_option.visible = false
	_unit_mode_layout.visible = false
	_loading_turn.visible = false
	_game_over.visible = false
	display_loading(false)
	set_process(false)
	
func _notification(what):
	match what:
		MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
			_on_back_pressed()
			return
			
		MainLoop.NOTIFICATION_WM_GO_BACK_REQUEST: 
			_on_back_pressed()
			return
			
func _process(delta):
	_loading_image.rect_rotation += 5.0
	
func _on_generate_pressed():
	emit_signal("generate_map")
	
func display_loading(_is_loading : bool):
	_loading.visible = _is_loading
	
func display_loading_progress(task_name : String, progress : int, max_task : int):
	_loading_label.text = task_name
	_loading_bar.value = progress
	_loading_bar.max_value = max_task
	
func display_control(_show : bool):
	_control.visible = _show
	
func display_loading_turn(_show : bool):
	_loading_turn.visible = _show
	set_process(_show)
	
func display_selection_mode():
	_selection_mode_layout.visible = true
	_unit_mode_layout.visible = false
	
func display_selected_unit(_show : bool):
	_selection_mode_layout.visible = not _show
	_unit_mode_layout.visible = _show
	
func display_unit_info():
	pass
	
func display_game_over(_is_win : bool, _message : String):
	_control.visible = false
	_loading_turn.visible = false
	_game_over.visible = true
	_game_over_condition.text = "You win!" if _is_win else "You Lose!"
	_game_over_message.text = "All enemy has been eliminated!" if _is_win else _message
	
func _on_find_movable_unit_btn_pressed():
	emit_signal("find_movable_unit")
	
func _on_skip_turn_pressed():
	emit_signal("skip_turn")
	
func _on_unit_info_pressed():
	emit_signal("get_unit_info")
	
func _on_deselect_pressed():
	display_selection_mode()
	emit_signal("deselect_unit")
	
func _on_exit_button_pressed():
	Network.disconnect_from_server()
	get_tree().change_scene("res://menu/main-menu/main_menu.tscn")
	
func _on_back_pressed():
	_dialog_exit_option.display_message("Attention!","Are you sure want quit?")
	_dialog_exit_option.visible = true
	
func _on_simple_dialog_option_on_yes():
	_on_exit_button_pressed()











