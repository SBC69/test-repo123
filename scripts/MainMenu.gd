extends Control

@onready var start_button = $VBoxContainer/StartButton
@onready var quit_button = $VBoxContainer/QuitButton
@onready var title = $VBoxContainer/Title

func _ready():
	start_button.pressed.connect(_on_start_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func _on_start_pressed():
	get_tree().change_scene_to_file("res://scenes/Level1.tscn")

func _on_quit_pressed():
	get_tree().quit()
