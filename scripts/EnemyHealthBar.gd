extends Control

## Полоска здоровья над врагом

@export var bar_width: float = 40.0
@export var bar_height: float = 6.0
@export var offset_y: float = -20.0  # Отступ над врагом

var enemy: CharacterBody2D = null
var health_bar: ColorRect = null
var background: ColorRect = null

func _ready() -> void:
	# Находим врага
	enemy = get_parent()
	if not enemy or not enemy.is_in_group("enemy"):
		push_error("EnemyHealthBar должен быть дочерним узлом Enemy")
		return
	
	# Создаём фон полоски
	background = ColorRect.new()
	background.name = "Background"
	background.color = Color(0, 0, 0, 0.7)
	background.size = Vector2(bar_width, bar_height)
	background.position = Vector2(-bar_width / 2, offset_y)
	add_child(background)
	
	# Создаём саму полоску здоровья
	health_bar = ColorRect.new()
	health_bar.name = "HealthBar"
	health_bar.color = Color(0, 1, 0)  # Зелёный
	health_bar.size = Vector2(bar_width - 2, bar_height - 2)
	health_bar.position = Vector2(-bar_width / 2 + 1, offset_y + 1)
	add_child(health_bar)
	
	# Начальное обновление
	_update_health_bar()

func _process(_delta: float) -> void:
	if enemy and enemy.health > 0:
		_update_health_bar()
	else:
		# Скрываем полоску при смерти
		visible = false

func _update_health_bar() -> void:
	"""Обновляет размер и цвет полоски здоровья"""
	if not enemy or not health_bar:
		return
	
	# Рассчитываем процент здоровья
	var health_percent = float(enemy.health) / 50.0  # max_health = 50
	health_percent = clamp(health_percent, 0.0, 1.0)
	
	# Обновляем ширину полоски
	var new_width = (bar_width - 2) * health_percent
	health_bar.size.x = new_width
	
	# Меняем цвет в зависимости от здоровья
	health_bar.color = _get_health_color(health_percent)

func _get_health_color(health_percent: float) -> Color:
	"""Возвращает цвет в зависимости от процента здоровья"""
	if health_percent > 0.5:
		# Зелёный (100%-50%)
		return Color(0, 1, 0)
	elif health_percent > 0.25:
		# Жёлтый (50%-25%)
		return Color(1, 1, 0)
	else:
		# Красный (25%-0%)
		return Color(1, 0, 0)
