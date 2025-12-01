extends CharacterBody2D

const SPEED = 200.0
const JUMP_VELOCITY = -400.0
const ATTACK_DAMAGE = 20

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var health = 100
var is_attacking = false
var facing_right = true

@onready var sprite = $Sprite2D
@onready var attack_area = $AttackArea

func _ready():
	add_to_group("player")
	attack_area.monitoring = false
	attack_area.body_entered.connect(_on_attack_area_body_entered)

func _physics_process(delta):
	if health <= 0:
		die()
		return
	
	# Гравитация
	if not is_on_floor():
		velocity.y += gravity * delta
	
	# Прыжок
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	# Атака
	if Input.is_action_just_pressed("attack") and not is_attacking:
		attack()
	
	# Движение
	if not is_attacking:
		var direction = Input.get_axis("move_left", "move_right")
		if direction:
			velocity.x = direction * SPEED
			if direction > 0:
				facing_right = true
				attack_area.scale.x = 1
			else:
				facing_right = false
				attack_area.scale.x = -1
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
	
	move_and_slide()

func attack():
	is_attacking = true
	attack_area.monitoring = true
	# Визуальная обратная связь - увеличим размер на момент атаки
	sprite.scale = Vector2(1.3, 1.3)
	await get_tree().create_timer(0.3).timeout
	sprite.scale = Vector2(1, 1)
	is_attacking = false
	attack_area.monitoring = false

func take_damage(damage: int):
	health -= damage
	# Красная вспышка при получении урона
	sprite.modulate = Color(1, 0.3, 0.3)
	await get_tree().create_timer(0.2).timeout
	sprite.modulate = Color(1, 1, 1)
	if health <= 0:
		die()

func die():
	sprite.modulate = Color(0.5, 0.5, 0.5)
	set_physics_process(false)
	await get_tree().create_timer(1.0).timeout
	get_tree().reload_current_scene()

func heal(amount: int):
	health = min(health + amount, 100)

func _on_attack_area_body_entered(body):
	if body.is_in_group("enemy"):
		if body.has_method("take_damage"):
			body.take_damage(ATTACK_DAMAGE)
