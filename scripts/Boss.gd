extends CharacterBody2D

const SPEED = 120.0
const JUMP_FORCE = -300.0
const ATTACK_DAMAGE = 25
const SPECIAL_ATTACK_DAMAGE = 40
const EXPERIENCE_REWARD = 100  # Большая награда за босса

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var health = 200
var max_health = 200
var player = null
var is_attacking = false
var attack_cooldown = 0.0
var phase = 1

@onready var sprite = $Sprite2D
@onready var health_bar = $HealthBar

signal boss_defeated

func _ready():
	add_to_group("enemy")
	health_bar.max_value = max_health
	health_bar.value = health

func _physics_process(delta):
	if health <= 0:
		return
	
	if not is_on_floor():
		velocity.y += gravity * delta
	
	attack_cooldown -= delta
	
	if player and is_instance_valid(player):
		var distance = global_position.distance_to(player.global_position)
		
		if attack_cooldown <= 0 and not is_attacking:
			if phase == 2 and randf() > 0.5:
				special_attack()
			else:
				attack()
		else:
			move_towards_player()
	
	move_and_slide()

func move_towards_player():
	if is_attacking:
		return
	
	var direction = sign(player.global_position.x - global_position.x)
	velocity.x = direction * SPEED

func attack():
	is_attacking = true
	velocity.x = 0
	attack_cooldown = 2.0
	sprite.scale = Vector2(1.3, 1.3)
	
	if player and player.has_method("take_damage"):
		var distance = global_position.distance_to(player.global_position)
		if distance < 80:
			player.take_damage(ATTACK_DAMAGE)
	
	await get_tree().create_timer(0.5).timeout
	sprite.scale = Vector2(1, 1)
	is_attacking = false

func special_attack():
	is_attacking = true
	velocity.x = 0
	attack_cooldown = 3.5
	sprite.modulate = Color(1.5, 1, 1)
	
	velocity.y = JUMP_FORCE
	await get_tree().create_timer(0.3).timeout
	
	if player and player.has_method("take_damage"):
		var distance = global_position.distance_to(player.global_position)
		if distance < 120:
			player.take_damage(SPECIAL_ATTACK_DAMAGE)
	
	await get_tree().create_timer(0.5).timeout
	sprite.modulate = Color(1, 1, 1) if phase == 1 else Color(1.2, 0.8, 0.8)
	is_attacking = false

func take_damage(damage: int, attacker_position: Vector2 = Vector2.ZERO):
	health -= damage
	health_bar.value = health
	sprite.modulate = Color(1, 0.3, 0.3)
	await get_tree().create_timer(0.2).timeout
	
	if health <= max_health / 2 and phase == 1:
		phase = 2
		sprite.modulate = Color(1.2, 0.8, 0.8)
	else:
		sprite.modulate = Color(1, 1, 1) if phase == 1 else Color(1.2, 0.8, 0.8)
	
	if health <= 0:
		die()

func die():
	remove_from_group("enemy")
	
	# Награда опытом за босса
	_grant_experience_to_player()
	
	sprite.modulate = Color(0.3, 0.3, 0.3)
	set_physics_process(false)
	$CollisionShape2D.set_deferred("disabled", true)
	boss_defeated.emit()
	await get_tree().create_timer(1.0).timeout
	queue_free()

func _grant_experience_to_player():
	var progression_system = get_tree().get_first_node_in_group("progression_system")
	if progression_system and progression_system.has_method("add_experience"):
		progression_system.add_experience(EXPERIENCE_REWARD)
		_show_exp_popup()

func _show_exp_popup():
	var label = Label.new()
	label.text = "+" + str(EXPERIENCE_REWARD) + " EXP (BOSS!)"
	label.modulate = Color(1, 0.8, 0)
	label.position = Vector2(-50, -120)
	label.z_index = 100
	label.add_theme_font_size_override("font_size", 24)
	add_child(label)
	
	var tween = create_tween()
	tween.tween_property(label, "position:y", label.position.y - 70, 1.5)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 1.5)
	
	await tween.finished
	label.queue_free()

func set_player(p):
	player = p
