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
@onready var animation_player = $AnimationPlayer
@onready var detection_area = $DetectionArea

func _ready():
	add_to_group("enemy")

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
	
	update_animation()

func patrol(delta):
	patrol_timer += delta
	if patrol_timer > 3.0:
		patrol_direction *= -1
		patrol_timer = 0.0
	
	velocity.x = patrol_direction * SPEED * 0.5
	sprite.flip_h = patrol_direction < 0

func chase_player():
	var direction = sign(player.global_position.x - global_position.x)
	velocity.x = direction * SPEED
	sprite.flip_h = direction < 0

func attack():
	is_attacking = true
	velocity.x = 0
	animation_player.play("attack")
	if player and player.has_method("take_damage"):
		player.take_damage(ATTACK_DAMAGE)
	await animation_player.animation_finished
	is_attacking = false

func update_animation():
	if is_attacking:
		return
	
	if velocity.x != 0:
		animation_player.play("run")
	else:
		animation_player.play("idle")

func take_damage(damage: int):
	health -= damage
	animation_player.play("hurt")
	if health <= 0:
		die()

func die():
	remove_from_group("enemy")
	animation_player.play("death")
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
