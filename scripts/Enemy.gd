extends CharacterBody2D

const SPEED = 80.0
const CHASE_RANGE = 300.0
const ATTACK_RANGE = 50.0
const ATTACK_DAMAGE = 10

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var health = 50
var player = null
var is_attacking = false
var patrol_direction = 1
var patrol_timer = 0.0

@onready var sprite = $Sprite2D
@onready var detection_area = $DetectionArea

func _ready():
	add_to_group("enemy")
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)

func _physics_process(delta):
	if health <= 0:
		return
	
	if not is_on_floor():
		velocity.y += gravity * delta
	
	if player and is_instance_valid(player):
		var distance = global_position.distance_to(player.global_position)
		
		if distance < ATTACK_RANGE and not is_attacking:
			attack()
		elif distance < CHASE_RANGE:
			chase_player()
		else:
			patrol(delta)
	else:
		patrol(delta)
	
	move_and_slide()

func patrol(delta):
	patrol_timer += delta
	if patrol_timer > 3.0:
		patrol_direction *= -1
		patrol_timer = 0.0
	
	velocity.x = patrol_direction * SPEED * 0.5

func chase_player():
	var direction = sign(player.global_position.x - global_position.x)
	velocity.x = direction * SPEED

func attack():
	is_attacking = true
	velocity.x = 0
	# Визуальная обратная связь
	sprite.scale = Vector2(1.2, 1.2)
	if player and player.has_method("take_damage"):
		player.take_damage(ATTACK_DAMAGE)
	await get_tree().create_timer(0.5).timeout
	sprite.scale = Vector2(1, 1)
	is_attacking = false

func take_damage(damage: int):
	health -= damage
	# Красная вспышка при получении урона
	sprite.modulate = Color(1, 0.3, 0.3)
	await get_tree().create_timer(0.2).timeout
	sprite.modulate = Color(1, 1, 1)
	if health <= 0:
		die()

func die():
	remove_from_group("enemy")
	sprite.modulate = Color(0.3, 0.3, 0.3)
	set_physics_process(false)
	$CollisionShape2D.set_deferred("disabled", true)
	await get_tree().create_timer(0.5).timeout
	queue_free()

func _on_detection_area_body_entered(body):
	if body.is_in_group("player"):
		player = body

func _on_detection_area_body_exited(body):
	if body.is_in_group("player"):
		player = null
