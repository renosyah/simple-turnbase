extends Control

onready var _server_browser = $CanvasLayer/server_browser

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
