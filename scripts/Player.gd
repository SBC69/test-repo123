extends CharacterBody2D

# Сигналы для связи с другими компонентами
signal health_changed(new_health: int, max_health: int)
signal died()
signal attacked()
signal damage_taken(damage: int)

# Экспортируемые переменные для настройки через инспектор
@export_group("Movement")
@export var speed: float = 200.0
@export var jump_velocity: float = -400.0
@export var acceleration: float = 1000.0
@export var friction: float = 1000.0

@export_group("Combat")
@export var max_health: int = 100
@export var attack_damage: int = 20
@export var attack_duration: float = 0.3
@export var invincibility_duration: float = 0.5

@export_group("Visual Feedback")
@export var damage_flash_color: Color = Color(1, 0.3, 0.3)
@export var damage_flash_duration: float = 0.2

# Состояния игрока
enum State {
	IDLE,
	WALKING,
	JUMPING,
	FALLING,
	ATTACKING,
	DEAD
}

# Внутренние переменные
var current_state: State = State.IDLE
var health: int = max_health
var is_invincible: bool = false
var facing_right: bool = true
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

# Ссылки на узлы (без типизации для совместимости с ColorRect/Sprite2D)
@onready var sprite = $Sprite2D
@onready var attack_area: Area2D = $AttackArea

func _ready() -> void:
	add_to_group("player")
	_initialize_nodes()
	health = max_health
	health_changed.emit(health, max_health)

func _initialize_nodes() -> void:
	"""Инициализация и проверка узлов"""
	if attack_area:
		attack_area.monitoring = false
		attack_area.body_entered.connect(_on_attack_area_body_entered)
	else:
		push_warning("Player: AttackArea node not found")
	
	if not sprite:
		push_warning("Player: Sprite2D node not found")

func _physics_process(delta: float) -> void:
	if current_state == State.DEAD:
		return
	
	_apply_gravity(delta)
	_handle_input()
	_update_state()
	_apply_movement(delta)
	move_and_slide()

func _apply_gravity(delta: float) -> void:
	"""Применение гравитации"""
	if not is_on_floor():
		velocity.y += gravity * delta

func _handle_input() -> void:
	"""Обработка пользовательского ввода"""
	if current_state == State.ATTACKING:
		return
	
	# Прыжок
	if Input.is_action_just_pressed("jump") and is_on_floor():
		_jump()
	
	# Атака
	if Input.is_action_just_pressed("attack"):
		_start_attack()

func _apply_movement(delta: float) -> void:
	"""Применение горизонтального движения"""
	if current_state == State.ATTACKING:
		velocity.x = move_toward(velocity.x, 0, friction * delta)
		return
	
	var direction := Input.get_axis("move_left", "move_right")
	
	if direction != 0:
		velocity.x = move_toward(velocity.x, direction * speed, acceleration * delta)
		_update_facing_direction(direction)
	else:
		velocity.x = move_toward(velocity.x, 0, friction * delta)

func _update_state() -> void:
	"""Обновление текущего состояния"""
	if current_state == State.ATTACKING or current_state == State.DEAD:
		return
	
	if not is_on_floor():
		current_state = State.FALLING if velocity.y > 0 else State.JUMPING
	elif abs(velocity.x) > 10:
		current_state = State.WALKING
	else:
		current_state = State.IDLE

func _update_facing_direction(direction: float) -> void:
	"""Обновление направления взгляда персонажа"""
	if direction > 0 and not facing_right:
		facing_right = true
		_flip_character()
	elif direction < 0 and facing_right:
		facing_right = false
		_flip_character()

func _flip_character() -> void:
	"""Отзеркаливание персонажа"""
	if sprite:
		# Для ColorRect используем scale.x, для Sprite2D - flip_h
		if sprite.has_method("set_flip_h"):
			# Это Sprite2D
			sprite.set("flip_h", not facing_right)
		else:
			# Это ColorRect или другой узел
			sprite.scale.x = -1 if not facing_right else 1
	
	if attack_area:
		attack_area.scale.x = 1 if facing_right else -1

func _jump() -> void:
	"""Выполнение прыжка"""
	velocity.y = jump_velocity
	current_state = State.JUMPING

func _start_attack() -> void:
	"""Начало атаки"""
	current_state = State.ATTACKING
	attacked.emit()
	
	if attack_area:
		attack_area.monitoring = true
	
	# Визуальная обратная связь
	if sprite:
		var current_scale_x = sprite.scale.x
		var scale_direction = 1 if current_scale_x >= 0 else -1
		sprite.scale = Vector2(1.3 * scale_direction, 1.3)
	
	await get_tree().create_timer(attack_duration).timeout
	_end_attack()

func _end_attack() -> void:
	"""Завершение атаки"""
	if current_state == State.DEAD:
		return
	
	current_state = State.IDLE
	
	if attack_area:
		attack_area.monitoring = false
	
	if sprite:
		var scale_direction = 1 if facing_right else -1
		sprite.scale = Vector2(scale_direction, 1)

func take_damage(damage: int) -> void:
	"""Получение урона"""
	if is_invincible or current_state == State.DEAD:
		return
	
	health -= damage
	health = max(health, 0)
	
	damage_taken.emit(damage)
	health_changed.emit(health, max_health)
	
	if health <= 0:
		_die()
	else:
		_start_invincibility()
		_play_damage_flash()

func _start_invincibility() -> void:
	"""Активация временной неуязвимости"""
	is_invincible = true
	await get_tree().create_timer(invincibility_duration).timeout
	is_invincible = false

func _play_damage_flash() -> void:
	"""Визуальная индикация получения урона"""
	if not sprite:
		return
	
	sprite.modulate = damage_flash_color
	await get_tree().create_timer(damage_flash_duration).timeout
	
	if current_state != State.DEAD and sprite:
		sprite.modulate = Color.WHITE

func _die() -> void:
	"""Смерть персонажа"""
	current_state = State.DEAD
	died.emit()
	
	if sprite:
		sprite.modulate = Color(0.5, 0.5, 0.5)
	
	set_physics_process(false)
	
	await get_tree().create_timer(1.0).timeout
	get_tree().reload_current_scene()

func heal(amount: int) -> void:
	"""Восстановление здоровья"""
	if current_state == State.DEAD:
		return
	
	health = min(health + amount, max_health)
	health_changed.emit(health, max_health)

func get_current_state() -> State:
	"""Получение текущего состояния"""
	return current_state

func is_alive() -> bool:
	"""Проверка, жив ли персонаж"""
	return current_state != State.DEAD

func _on_attack_area_body_entered(body: Node2D) -> void:
	"""Обработка попадания атаки по врагу"""
	if not body.is_in_group("enemy"):
		return
	
	if body.has_method("take_damage"):
		body.take_damage(attack_damage)
