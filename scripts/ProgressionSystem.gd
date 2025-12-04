extends Node

# Singleton для управления прогрессией игрока

signal level_up(new_level: int)
signal experience_gained(amount: int)
signal skill_unlocked(skill_name: String)
signal stats_changed()

# Базовые параметры
var current_level: int = 1
var current_experience: int = 0
var skill_points: int = 0

# Формула опыта: base_exp * level^1.5
const BASE_EXPERIENCE_FOR_LEVEL: int = 100

# Дерево навыков
var skills: Dictionary = {
	"max_health_1": {"unlocked": false, "cost": 1, "name": "Крепкое здоровье I", "description": "+20 HP"},
	"max_health_2": {"unlocked": false, "cost": 1, "name": "Крепкое здоровье II", "description": "+30 HP", "requires": "max_health_1"},
	"max_health_3": {"unlocked": false, "cost": 2, "name": "Крепкое здоровье III", "description": "+50 HP", "requires": "max_health_2"},
	
	"attack_damage_1": {"unlocked": false, "cost": 1, "name": "Острый клинок I", "description": "+5 урона атаки"},
	"attack_damage_2": {"unlocked": false, "cost": 1, "name": "Острый клинок II", "description": "+10 урона атаки", "requires": "attack_damage_1"},
	"attack_damage_3": {"unlocked": false, "cost": 2, "name": "Острый клинок III", "description": "+15 урона атаки", "requires": "attack_damage_2"},
	
	"stomp_damage_1": {"unlocked": false, "cost": 1, "name": "Мощный прыжок I", "description": "+10 урона прыжка"},
	"stomp_damage_2": {"unlocked": false, "cost": 1, "name": "Мощный прыжок II", "description": "+15 урона прыжка", "requires": "stomp_damage_1"},
	"stomp_damage_3": {"unlocked": false, "cost": 2, "name": "Мощный прыжок III", "description": "+20 урона прыжка", "requires": "stomp_damage_2"},
	
	"speed_1": {"unlocked": false, "cost": 1, "name": "Быстрые ноги I", "description": "+20 скорости"},
	"speed_2": {"unlocked": false, "cost": 2, "name": "Быстрые ноги II", "description": "+30 скорости", "requires": "speed_1"},
	
	"jump_power_1": {"unlocked": false, "cost": 1, "name": "Высокий прыжок I", "description": "+50 силы прыжка"},
	"jump_power_2": {"unlocked": false, "cost": 2, "name": "Высокий прыжок II", "description": "+100 силы прыжка", "requires": "jump_power_1"},
	
	"lifesteal": {"unlocked": false, "cost": 3, "name": "Вампиризм", "description": "Восстанавливает 20% от урона"},
	"double_jump": {"unlocked": false, "cost": 3, "name": "Двойной прыжок", "description": "Позволяет прыгнуть в воздухе"},
	"critical_hit": {"unlocked": false, "cost": 2, "name": "Критический удар", "description": "20% шанс удвоить урон"},
}

# Модификаторы статов из навыков
var stat_modifiers: Dictionary = {
	"max_health": 0,
	"attack_damage": 0,
	"stomp_damage": 0,
	"speed": 0,
	"jump_power": 0,
}

func _ready() -> void:
	add_to_group("progression_system")

func add_experience(amount: int) -> void:
	"""Добавить опыт и проверить повышение уровня"""
	current_experience += amount
	experience_gained.emit(amount)
	
	# Проверка повышения уровня
	var exp_needed = get_experience_for_next_level()
	while current_experience >= exp_needed:
		current_experience -= exp_needed
		_level_up()
		exp_needed = get_experience_for_next_level()

func _level_up() -> void:
	"""Повышение уровня"""
	current_level += 1
	skill_points += 1
	level_up.emit(current_level)
	
	print("Level up! Новый уровень: ", current_level)

func get_experience_for_next_level() -> int:
	"""Расчёт опыта для следующего уровня"""
	return int(BASE_EXPERIENCE_FOR_LEVEL * pow(current_level, 1.5))

func can_unlock_skill(skill_id: String) -> bool:
	"""Проверка возможности разблокировки навыка"""
	if not skills.has(skill_id):
		return false
	
	var skill = skills[skill_id]
	
	# Уже разблокирован
	if skill["unlocked"]:
		return false
	
	# Недостаточно очков навыков
	if skill_points < skill["cost"]:
		return false
	
	# Проверка требований
	if skill.has("requires"):
		var required_skill = skill["requires"]
		if not skills[required_skill]["unlocked"]:
			return false
	
	return true

func unlock_skill(skill_id: String) -> bool:
	"""Разблокировка навыка"""
	if not can_unlock_skill(skill_id):
		return false
	
	var skill = skills[skill_id]
	skill_points -= skill["cost"]
	skill["unlocked"] = true
	
	# Применение бонусов навыка
	_apply_skill_bonus(skill_id)
	
	skill_unlocked.emit(skill["name"])
	stats_changed.emit()
	
	print("Навык разблокирован: ", skill["name"])
	return true

func _apply_skill_bonus(skill_id: String) -> void:
	"""Применение бонусов от навыка к статам"""
	match skill_id:
		"max_health_1":
			stat_modifiers["max_health"] += 20
		"max_health_2":
			stat_modifiers["max_health"] += 30
		"max_health_3":
			stat_modifiers["max_health"] += 50
		
		"attack_damage_1":
			stat_modifiers["attack_damage"] += 5
		"attack_damage_2":
			stat_modifiers["attack_damage"] += 10
		"attack_damage_3":
			stat_modifiers["attack_damage"] += 15
		
		"stomp_damage_1":
			stat_modifiers["stomp_damage"] += 10
		"stomp_damage_2":
			stat_modifiers["stomp_damage"] += 15
		"stomp_damage_3":
			stat_modifiers["stomp_damage"] += 20
		
		"speed_1":
			stat_modifiers["speed"] += 20
		"speed_2":
			stat_modifiers["speed"] += 30
		
		"jump_power_1":
			stat_modifiers["jump_power"] += 50
		"jump_power_2":
			stat_modifiers["jump_power"] += 100

func get_stat_modifier(stat_name: String) -> int:
	"""Получить модификатор стата"""
	if stat_modifiers.has(stat_name):
		return stat_modifiers[stat_name]
	return 0

func has_skill(skill_id: String) -> bool:
	"""Проверка наличия навыка"""
	if not skills.has(skill_id):
		return false
	return skills[skill_id]["unlocked"]

func reset_progression() -> void:
	"""Сброс прогрессии (для новой игры)"""
	current_level = 1
	current_experience = 0
	skill_points = 0
	
	for skill_id in skills.keys():
		skills[skill_id]["unlocked"] = false
	
	stat_modifiers = {
		"max_health": 0,
		"attack_damage": 0,
		"stomp_damage": 0,
		"speed": 0,
		"jump_power": 0,
	}
	
	stats_changed.emit()

func get_progress_data() -> Dictionary:
	"""Получить данные прогрессии для сохранения"""
	return {
		"level": current_level,
		"experience": current_experience,
		"skill_points": skill_points,
		"skills": skills.duplicate(true),
		"stat_modifiers": stat_modifiers.duplicate(),
	}

func load_progress_data(data: Dictionary) -> void:
	"""Загрузить данные прогрессии"""
	if data.has("level"):
		current_level = data["level"]
	if data.has("experience"):
		current_experience = data["experience"]
	if data.has("skill_points"):
		skill_points = data["skill_points"]
	if data.has("skills"):
		skills = data["skills"].duplicate(true)
	if data.has("stat_modifiers"):
		stat_modifiers = data["stat_modifiers"].duplicate()
	
	stats_changed.emit()
