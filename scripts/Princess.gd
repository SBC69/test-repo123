extends Area2D

signal princess_rescued

@onready var sprite = $Sprite2D
@onready var animation_player = $AnimationPlayer

func _ready():
	animation_player.play("idle")

func _on_body_entered(body):
	if body.is_in_group("player"):
		rescue()

func rescue():
	animation_player.play("happy")
	princess_rescued.emit()
	await get_tree().create_timer(1.0).timeout
	queue_free()
