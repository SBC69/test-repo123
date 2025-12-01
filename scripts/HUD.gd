extends CanvasLayer

@onready var health_bar = $MarginContainer/HBoxContainer/HealthBar
@onready var health_label = $MarginContainer/HBoxContainer/HealthLabel

func _ready():
	update_health(100)

func update_health(value: int):
	health_bar.value = value
	health_label.text = "Здоровье: " + str(value)
