extends Control

signal on_yes
signal on_no

onready var _title = $VBoxContainer/HBoxContainer/Panel/VBoxContainer/HBoxContainer3/Label
onready var _message = $VBoxContainer/HBoxContainer/Panel/VBoxContainer/HBoxContainer2/message

func display_message(title, message : String):
	_title.text = title
	_message.text = message
	
func _on_no_pressed():
	visible = false
	emit_signal("on_no")

func _on_yes_pressed():
	visible = false
	emit_signal("on_yes")
