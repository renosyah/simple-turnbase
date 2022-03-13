extends Control

onready var _loading = $CanvasLayer/loading

onready var _loading_label = $CanvasLayer/loading/VBoxContainer/Label
onready var _loading_bar = $CanvasLayer/loading/VBoxContainer/loading_bar

func _ready():
	display_loading(false)
	
func _on_generate_pressed():
	emit_signal("generate_map")
	
func display_loading(_is_loading : bool):
	_loading.visible = _is_loading
	
func display_loading_progress(task_name : String, progress : int, max_task : int):
	_loading_label.text = task_name
	_loading_bar.value = progress
	_loading_bar.max_value = max_task
