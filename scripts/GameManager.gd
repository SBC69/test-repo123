extends Node

var current_level = 1
var player_health = 100
var collected_items = 0

func _ready():
	pass

func next_level():
	current_level += 1
	get_tree().change_scene_to_file("res://scenes/Level" + str(current_level) + ".tscn")

func game_over():
	get_tree().change_scene_to_file("res://scenes/GameOver.tscn")

func victory():
	get_tree().change_scene_to_file("res://scenes/Victory.tscn")

func restart():
	current_level = 1
	player_health = 100
	collected_items = 0
	get_tree().change_scene_to_file("res://scenes/Level1.tscn")
