extends Camera2D

# Экспортируемые переменные для настройки
@export_group("Camera Settings")
@export var smoothing_enabled: bool = true
@export var smoothing_speed: float = 5.0

@export_group("Camera Bounds")
@export var use_limits: bool = false
@export var limit_left_value: int = -10000000
@export var limit_top_value: int = -10000000
@export var limit_right_value: int = 10000000
@export var limit_bottom_value: int = 10000000

func _ready() -> void:
	# Делаем эту камеру активной
	make_current()
	
	# Включаем сглаживание камеры
	position_smoothing_enabled = smoothing_enabled
	position_smoothing_speed = smoothing_speed
	
	# Устанавливаем границы камеры
	if use_limits:
		limit_left = limit_left_value
		limit_top = limit_top_value
		limit_right = limit_right_value
		limit_bottom = limit_bottom_value
	
	print("PlayerCamera: Camera activated")

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
