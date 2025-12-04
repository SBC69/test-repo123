extends Area2D

@export var next_level_path: String = ""

var player_in_area: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(_delta: float) -> void:
	if player_in_area and Input.is_action_just_pressed("ui_accept"):
		_transition_to_next_level()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_area = true
		# Автоматический переход через 1 секунду
		await get_tree().create_timer(1.0).timeout
		if player_in_area:
			_transition_to_next_level()

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_area = false

func _transition_to_next_level() -> void:
	if next_level_path.is_empty():
		push_warning("LevelTransition: next_level_path is not set")
		return
	
	get_tree().change_scene_to_file(next_level_path)
