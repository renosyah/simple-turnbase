extends Control

onready var _server_browser = $CanvasLayer/server_browser
onready var _dialog_exit_option = $CanvasLayer/simple_dialog_option

func _ready():
	_server_browser.start_finding()
	_dialog_exit_option.visible = false
	get_tree().set_quit_on_go_back(false)
	get_tree().set_auto_accept_quit(false)
	
func _notification(what):
	match what:
		MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
			_on_back_pressed()
			return
			
		MainLoop.NOTIFICATION_WM_GO_BACK_REQUEST: 
			_on_back_pressed()
			return
	
func _on_host_pressed():
	Global.mode = Global.MODE_HOST
	get_tree().change_scene("res://menu/lobby-menu/lobby_menu.tscn")
	
func _on_join_pressed():
	_server_browser.visible = true

func _on_server_browser_on_error(msg):
	print(msg)
	
func _on_server_browser_on_join(info):
	Global.mode = Global.MODE_JOIN
	Global.client.ip = info["ip"]
	get_tree().change_scene("res://menu/lobby-menu/lobby_menu.tscn")
	
func _on_server_browser_close():
	_server_browser.visible = false
	
func _on_back_pressed():
	_dialog_exit_option.display_message("Attention!","Are you sure want exit?")
	_dialog_exit_option.visible = true
	
func _on_simple_dialog_option_on_yes():
	get_tree().quit()





















