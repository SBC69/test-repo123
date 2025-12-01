extends Camera2D

# Экспортируемые переменные для настройки
@export_group("Follow Settings")
@export var follow_player: bool = true
@export var smoothing_enabled: bool = true
@export var smoothing_speed: float = 5.0

@export_group("Camera Bounds")
@export var use_limits: bool = false
@export var limit_left_value: int = -10000000
@export var limit_top_value: int = -10000000
@export var limit_right_value: int = 10000000
@export var limit_bottom_value: int = 10000000

@export_group("Offset")
@export var camera_offset: Vector2 = Vector2.ZERO

var player: CharacterBody2D = null

func _ready() -> void:
	# Включаем сглаживание камеры
	position_smoothing_enabled = smoothing_enabled
	position_smoothing_speed = smoothing_speed
	
	# Устанавливаем границы камеры
	if use_limits:
		limit_left = limit_left_value
		limit_top = limit_top_value
		limit_right = limit_right_value
		limit_bottom = limit_bottom_value
	
	# Ищем игрока
	_find_player()
	
	# Если игрок найден, устанавливаем начальную позицию
	if player:
		global_position = player.global_position + camera_offset

func _find_player() -> void:
	"""Поиск игрока в сцене"""
	# Ищем в группе "player"
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0] as CharacterBody2D
		if player:
			print("PlayerCamera: Player found")
		else:
			push_warning("PlayerCamera: Node in 'player' group is not CharacterBody2D")
	else:
		push_warning("PlayerCamera: No player found in scene")

func _process(_delta: float) -> void:
	if not follow_player:
		return
	
	# Если игрок не найден, пытаемся найти снова
	if not player:
		_find_player()
		return
	
	# Проверяем, что игрок всё ещё существует
	if not is_instance_valid(player):
		player = null
		return
	
	# Следуем за игроком
	global_position = player.global_position + camera_offset

func set_follow_target(target: Node2D) -> void:
	"""Установить цель для слежения вручную"""
	if target is CharacterBody2D:
		player = target
		print("PlayerCamera: Follow target set manually")
	else:
		push_warning("PlayerCamera: Target is not CharacterBody2D")

func shake(intensity: float = 10.0, duration: float = 0.3) -> void:
	"""Эффект тряски камеры"""
	var original_offset = offset
	var shake_time = 0.0
	
	while shake_time < duration:
		offset = Vector2(
			randf_range(-intensity, intensity),
			randf_range(-intensity, intensity)
		)
		shake_time += get_process_delta_time()
		await get_tree().process_frame
	
	offset = original_offset
