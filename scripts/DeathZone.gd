extends Area2D

## Зона смерти - перезагружает уровень при падении игрока

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		# Убиваем игрока или перезагружаем уровень
		if body.has_method("take_damage"):
			body.take_damage(999)  # Смертельный урон
		else:
			get_tree().reload_current_scene()
	elif body.is_in_group("enemy"):
		# Враги тоже умирают от падения
		body.queue_free()
