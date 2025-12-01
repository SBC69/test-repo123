extends Area2D

signal princess_rescued

@onready var sprite = $Sprite2D

func _ready():
	body_entered.connect(_on_body_entered)
	# Простая "анимация" - мигание
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(sprite, "modulate:a", 0.5, 1.0)
	tween.tween_property(sprite, "modulate:a", 1.0, 1.0)

func _on_body_entered(body):
	if body.is_in_group("player"):
		rescue()

func rescue():
	# Эффект радости - увеличение размера
	var tween = create_tween()
	tween.tween_property(sprite, "scale", Vector2(1.5, 1.5), 0.3)
	princess_rescued.emit()
	await get_tree().create_timer(1.0).timeout
	queue_free()
