extends CanvasLayer

## UI для отображения здоровья игрока в виде сердец

@export var max_hearts: int = 3
@export var heart_size: Vector2 = Vector2(32, 32)
@export var heart_spacing: float = 5.0

var hearts: Array[ColorRect] = []
var player: CharacterBody2D = null

@onready var heart_container: HBoxContainer = $HeartContainer

func _ready() -> void:
	# Находим игрока (родителя этого CanvasLayer)
	player = get_parent()
	if not player:
		push_error("PlayerHealthUI: не найден родительский узел")
		return
	
	# Проверяем наличие сигнала
	if not player.has_signal("health_changed"):
		push_error("PlayerHealthUI: У Player нет сигнала health_changed")
		return
	
	# Подключаемся к сигналам
	player.health_changed.connect(_on_health_changed)
	
	# Создаём сердца
	_create_hearts()
	
	# Устанавливаем начальное здоровье
	if "health" in player and "max_health" in player:
		_update_hearts(player.health, player.max_health)

func _create_hearts() -> void:
	"""Создаёт визуальные сердца"""
	for i in max_hearts:
		var heart = ColorRect.new()
		heart.custom_minimum_size = heart_size
		heart.color = Color(1, 0, 0)  # Красный
		heart.name = "Heart" + str(i + 1)
		heart_container.add_child(heart)
		hearts.append(heart)

func _on_health_changed(current_health: int, max_health: int) -> void:
	"""Обновляет отображение сердец при изменении здоровья"""
	_update_hearts(current_health, max_health)
	
	# Анимация тряски при получении урона
	if current_health < max_health:
		_shake_hearts()

func _update_hearts(current_health: int, max_health: int) -> void:
	"""Обновляет видимость сердец"""
	var health_per_heart = float(max_health) / max_hearts
	
	for i in hearts.size():
		var heart = hearts[i]
		var heart_threshold = (i + 1) * health_per_heart
		
		if current_health >= heart_threshold:
			# Полное сердце
			heart.visible = true
			heart.modulate = Color.WHITE
		elif current_health > (i * health_per_heart):
			# Частично заполненное сердце (полупрозрачное)
			heart.visible = true
			heart.modulate = Color(1, 1, 1, 0.5)
		else:
			# Пустое сердце
			heart.visible = false

func _shake_hearts() -> void:
	"""Анимация тряски сердец при получении урона"""
	var original_pos = heart_container.position
	var shake_amount = 5.0
	var shake_duration = 0.3
	var shake_count = 6
	
	for i in shake_count:
		var shake_offset = Vector2(
			randf_range(-shake_amount, shake_amount),
			randf_range(-shake_amount, shake_amount)
		)
		heart_container.position = original_pos + shake_offset
		await get_tree().create_timer(shake_duration / shake_count).timeout
	
	heart_container.position = original_pos
