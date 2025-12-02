extends Control

## Полоска здоровья над врагом

@export var bar_width: float = 40.0
@export var bar_height: float = 6.0
@export var offset_y: float = -35.0  # Отступ над врагом (увеличен)

var enemy: CharacterBody2D = null
var health_bar: ColorRect = null
var background: ColorRect = null

func _ready() -> void:
	# Находим врага (родителя)
	enemy = get_parent()
	if not enemy:
		print("EnemyHealthBar: Ошибка - нет родителя")
		return
	
	print("EnemyHealthBar: Инициализация для ", enemy.name)
	
	# Проверяем наличие свойства health
	if not "health" in enemy:
		print("EnemyHealthBar: Ошибка - у врага нет свойства health")
		return
	
	# Создаём фон полоски
	background = ColorRect.new()
	background.name = "Background"
	background.color = Color(0, 0, 0, 0.8)
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
	
	# Устанавливаем размер Control
	custom_minimum_size = Vector2(bar_width, bar_height)
	size = Vector2(bar_width, bar_height + abs(offset_y))
	
	# Начальное обновление
	_update_health_bar()
	
	print("EnemyHealthBar: Создан успешно")

func _process(_delta: float) -> void:
	if not enemy:
		return
	
	if "health" in enemy and enemy.health > 0:
		_update_health_bar()
	else:
		# Скрываем полоску при смерти
		visible = false

func _update_health_bar() -> void:
	"""Обновляет размер и цвет полоски здоровья"""
	if not enemy or not health_bar:
		return
	
	# Рассчитываем процент здоровья
	var max_hp = 50  # Берём из Enemy.gd
	if "health" in enemy:
		var health_percent = float(enemy.health) / float(max_hp)
		health_percent = clamp(health_percent, 0.0, 1.0)
		
		# Обновляем ширину полоски
		var new_width = (bar_width - 2) * health_percent
		health_bar.size.x = new_width
		
		# Меняем цвет в зависимости от здоровья
		health_bar.color = _get_health_color(health_percent)
		
		# Показываем полоску
		visible = true

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
