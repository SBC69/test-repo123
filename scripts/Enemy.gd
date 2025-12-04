extends CharacterBody2D

const SPEED = 80.0
const CHASE_RANGE = 300.0
const ATTACK_RANGE = 50.0
const ATTACK_DAMAGE = 10
const KNOCKBACK_FORCE = 200.0
const EXPERIENCE_REWARD = 25  # Награда за убийство

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var health = 50
var player = null
var is_attacking = false
var is_taking_damage = false
var patrol_direction = 1
var patrol_timer = 0.0
var knockback_velocity = Vector2.ZERO
var facing_right = true

@onready var sprite = $AnimatedSprite2D
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
	
	if knockback_velocity != Vector2.ZERO:
		velocity.x = knockback_velocity.x
		velocity.y = knockback_velocity.y
		knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, 10 * delta)
		if knockback_velocity.length() < 10:
			knockback_velocity = Vector2.ZERO
	elif not is_taking_damage:
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
	
	_update_sprite_direction()
	move_and_slide()

func _update_sprite_direction():
	if not sprite:
		return
	
	if velocity.x > 10 and not facing_right:
		facing_right = true
		sprite.flip_h = false
	elif velocity.x < -10 and facing_right:
		facing_right = false
		sprite.flip_h = true

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
	if player and "is_invincible" in player and player.is_invincible:
		return
	
	is_attacking = true
	velocity.x = 0
	if sprite:
		sprite.scale = Vector2(1.2, 1.2)
	if player and player.has_method("take_damage"):
		player.take_damage(ATTACK_DAMAGE)
	await get_tree().create_timer(0.5).timeout
	if sprite:
		sprite.scale = Vector2(1, 1)
	is_attacking = false

func take_damage(damage: int, attacker_position: Vector2 = Vector2.ZERO):
	if health <= 0:
		return
	
	health -= damage
	is_taking_damage = true
	
	if attacker_position != Vector2.ZERO:
		var knockback_direction = (global_position - attacker_position).normalized()
		knockback_velocity = knockback_direction * KNOCKBACK_FORCE
		knockback_velocity.y = -100
	
	_play_damage_effect()
	
	if health <= 0:
		die()
	else:
		await get_tree().create_timer(0.3).timeout
		is_taking_damage = false

func _play_damage_effect():
	if not sprite:
		return
	
	var original_position = sprite.position
	var original_scale = sprite.scale
	var shake_intensity = 3.0
	var shake_duration = 0.15
	var flash_count = 3
	
	for i in flash_count:
		sprite.modulate = Color(1.0, 0.0, 0.0)
		sprite.position = original_position + Vector2(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity)
		)
		sprite.scale = original_scale * 1.1
		await get_tree().create_timer(shake_duration / (flash_count * 2)).timeout
		
		sprite.modulate = Color.WHITE
		sprite.position = original_position
		sprite.scale = original_scale
		await get_tree().create_timer(shake_duration / (flash_count * 2)).timeout
	
	sprite.modulate = Color.WHITE
	sprite.position = original_position
	sprite.scale = original_scale

func die():
	remove_from_group("enemy")
	is_taking_damage = false
	
	# Награда опытом
	_grant_experience_to_player()
	
	if not sprite:
		queue_free()
		return
	
	sprite.modulate = Color(0.3, 0.3, 0.3)
	set_physics_process(false)
	
	if has_node("CollisionShape2D"):
		$CollisionShape2D.set_deferred("disabled", true)
	
	var tween = create_tween()
	tween.tween_property(sprite, "rotation", PI, 0.5)
	tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.5)
	
	await get_tree().create_timer(0.5).timeout
	queue_free()

func _grant_experience_to_player():
	"""Выдача опыта игроку"""
	var progression_system = get_tree().get_first_node_in_group("progression_system")
	if progression_system and progression_system.has_method("add_experience"):
		progression_system.add_experience(EXPERIENCE_REWARD)
		# Визуальная подсказка
		_show_exp_popup()

func _show_exp_popup():
	"""Показ всплывающего текста с опытом"""
	var label = Label.new()
	label.text = "+" + str(EXPERIENCE_REWARD) + " EXP"
	label.modulate = Color(1, 1, 0.5)
	label.position = Vector2(-30, -80)
	label.z_index = 100
	add_child(label)
	
	var tween = create_tween()
	tween.tween_property(label, "position:y", label.position.y - 50, 1.0)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 1.0)
	
	await tween.finished
	label.queue_free()

func _on_detection_area_body_entered(body):
	if body.is_in_group("player"):
		player = body

func _on_detection_area_body_exited(body):
	if body.is_in_group("player"):
		player = null
