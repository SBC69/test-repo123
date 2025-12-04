extends CanvasLayer

var progression_system: Node = null

@onready var level_label = $Panel/VBoxContainer/Header/LevelLabel
@onready var skill_points_label = $Panel/VBoxContainer/Header/SkillPointsLabel
@onready var exp_label = $Panel/VBoxContainer/ProgressInfo/ExpLabel
@onready var exp_bar = $Panel/VBoxContainer/ProgressInfo/ExpBar
@onready var close_button = $Panel/VBoxContainer/Header/CloseButton
@onready var info_label = $Panel/VBoxContainer/InfoLabel

@onready var health_category = $Panel/VBoxContainer/ScrollContainer/SkillsGrid/HealthCategory
@onready var attack_category = $Panel/VBoxContainer/ScrollContainer/SkillsGrid/AttackCategory
@onready var mobility_category = $Panel/VBoxContainer/ScrollContainer/SkillsGrid/MobilityCategory

var skill_buttons: Dictionary = {}

func _ready() -> void:
	hide()
	close_button.pressed.connect(_on_close_pressed)
	
	# Получаем систему прогрессии
	progression_system = get_tree().get_first_node_in_group("progression_system")
	
	if progression_system:
		progression_system.level_up.connect(_update_ui)
		progression_system.experience_gained.connect(_update_ui.unbind(1))
		progression_system.skill_unlocked.connect(_on_skill_unlocked)
		progression_system.stats_changed.connect(_update_ui)
	
	_create_skill_buttons()
	_update_ui()

func _process(_delta: float) -> void:
	# Открытие/закрытие дерева навыков на TAB
	if Input.is_action_just_pressed("ui_focus_next"): # TAB
		if visible:
			hide()
			get_tree().paused = false
		else:
			show()
			get_tree().paused = true
			_update_ui()

func _create_skill_buttons() -> void:
	"""Создание кнопок для всех навыков"""
	if not progression_system:
		return
	
	# Категории навыков
	var health_skills = ["max_health_1", "max_health_2", "max_health_3"]
	var attack_skills = ["attack_damage_1", "attack_damage_2", "attack_damage_3", 
						 "stomp_damage_1", "stomp_damage_2", "stomp_damage_3",
						 "critical_hit", "lifesteal"]
	var mobility_skills = ["speed_1", "speed_2", "jump_power_1", "jump_power_2", "double_jump"]
	
	_add_skills_to_category(health_category, health_skills)
	_add_skills_to_category(attack_category, attack_skills)
	_add_skills_to_category(mobility_category, mobility_skills)

func _add_skills_to_category(category: VBoxContainer, skill_ids: Array) -> void:
	"""Добавление навыков в категорию"""
	for skill_id in skill_ids:
		if not progression_system.skills.has(skill_id):
			continue
		
		var skill = progression_system.skills[skill_id]
		
		var button = Button.new()
		button.text = skill["name"] + " (" + str(skill["cost"]) + " SP)"
		button.tooltip_text = skill["description"]
		button.custom_minimum_size = Vector2(250, 40)
		button.pressed.connect(_on_skill_button_pressed.bind(skill_id))
		
		category.add_child(button)
		skill_buttons[skill_id] = button

func _update_ui(_param = null) -> void:
	"""Обновление UI"""
	if not progression_system or not visible:
		return
	
	# Обновление заголовка
	level_label.text = "Уровень: " + str(progression_system.current_level)
	skill_points_label.text = "Очки навыков: " + str(progression_system.skill_points)
	
	# Обновление опыта
	var current_exp = progression_system.current_experience
	var needed_exp = progression_system.get_experience_for_next_level()
	exp_label.text = "Опыт: " + str(current_exp) + " / " + str(needed_exp)
	exp_bar.max_value = needed_exp
	exp_bar.value = current_exp
	
	# Обновление кнопок навыков
	for skill_id in skill_buttons.keys():
		var button = skill_buttons[skill_id]
		var skill = progression_system.skills[skill_id]
		
		if skill["unlocked"]:
			button.disabled = true
			button.modulate = Color(0.5, 1, 0.5)
			button.text = skill["name"] + " [ПОЛУЧЕНО]"
		else:
			var can_unlock = progression_system.can_unlock_skill(skill_id)
			button.disabled = not can_unlock
			button.modulate = Color(1, 1, 1) if can_unlock else Color(0.5, 0.5, 0.5)

func _on_skill_button_pressed(skill_id: String) -> void:
	"""Обработка нажатия на кнопку навыка"""
	if not progression_system:
		return
	
	if progression_system.unlock_skill(skill_id):
		var skill = progression_system.skills[skill_id]
		info_label.text = "Разблокирован: " + skill["name"]
		_update_ui()
	else:
		info_label.text = "Невозможно разблокировать навык"

func _on_skill_unlocked(skill_name: String) -> void:
	"""Уведомление о разблокировке навыка"""
	info_label.text = "Получен навык: " + skill_name

func _on_close_pressed() -> void:
	"""Закрытие окна"""
	hide()
	get_tree().paused = false
