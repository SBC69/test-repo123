extends CharacterBody2D

const SPEED = 200.0
const JUMP_VELOCITY = -400.0
const ATTACK_DAMAGE = 20

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var health = 100
var is_attacking = false
var facing_right = true

@onready var sprite = $Sprite2D
@onready var animation_player = $AnimationPlayer
@onready var attack_area = $AttackArea

func _ready():
	attack_area.monitoring = false

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
				sprite.flip_h = false
				attack_area.scale.x = 1
			else:
				facing_right = false
				sprite.flip_h = true
				attack_area.scale.x = -1
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
	
	move_and_slide()
	
	# Анимации
	update_animation()

func update_animation():
	if is_attacking:
		return
	
	if not is_on_floor():
		animation_player.play("jump")
	elif velocity.x != 0:
		animation_player.play("run")
	else:
		animation_player.play("idle")

func attack():
	is_attacking = true
	attack_area.monitoring = true
	animation_player.play("attack")
	await animation_player.animation_finished
	is_attacking = false
	attack_area.monitoring = false

func take_damage(damage: int):
	health -= damage
	animation_player.play("hurt")
	if health <= 0:
		die()

func die():
	animation_player.play("death")
	set_physics_process(false)
	await get_tree().create_timer(1.0).timeout
	get_tree().reload_current_scene()

func heal(amount: int):
	health = min(health + amount, 100)

func _on_attack_area_body_entered(body):
	if body.is_in_group("enemy"):
		if body.has_method("take_damage"):
			body.take_damage(ATTACK_DAMAGE)
