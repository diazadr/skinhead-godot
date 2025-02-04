extends CharacterBody2D

@onready var animated_sprite = $Sprite2D
@onready var anim = $AnimationPlayer
@onready var animTree = $AnimationTree
@onready var AtkTimer = $AttackTimer
@export var Speed: int = 50
@export var Friction: float = 0.15
@export var Acceleration: int = 40
@export var AtkNumber: int = 3
@export var Health: int = 4
@export var attackpow: int = 1
@export var knockback_strength = 100

@onready var Projectile = preload("res://Player/Projectiles/Projectile.tscn")

var knockback_dir = Vector2.ZERO
var knockback = Vector2(0, 0)
var is_moving = false
var is_attacking = false
var state_machine  # Untuk playback AnimationTree

signal health_changed(value)
signal follower_interacted
signal enemy_attacked

func _ready():
	state_machine = animTree.get("parameters/playback")  # Inisialisasi state machine
	animTree.active = true

func _physics_process(delta):
	if Health <= 0:
		Death()

	knockback = knockback.move_toward(Vector2.ZERO, 200 * delta)
	var input_vector = Vector2.ZERO
	if is_attacking == false:
		input_vector.x = Input.get_action_strength("right") - Input.get_action_strength("left")
		input_vector.y = Input.get_action_strength("down") - Input.get_action_strength("up")

		velocity = input_vector * Speed + knockback

		if input_vector == Vector2.ZERO:
			state_machine.travel("Idle")
		else:
			knockback_dir = input_vector
			state_machine.travel("Run")
			animTree.set("parameters/Idle/blend_position", input_vector)
			animTree.set("parameters/Run/blend_position", input_vector)
			animTree.set("parameters/Attack1/blend_position", input_vector)
			animTree.set("parameters/Attack2/blend_position", input_vector)
			animTree.set("parameters/Attack3/blend_position", input_vector)
			animTree.set("parameters/Cast/blend_position", input_vector)  # Baru untuk serangan jarak jauh

		if Input.is_action_pressed("interact"):
			emit_signal("follower_interacted")

		move()

	attack_combo()

func attack_combo():
	if PlayerData.Class == 1:  # Class 1 untuk serangan melee
		if Input.is_action_just_pressed("attack") and AtkNumber == 3:
			is_attacking = true
			AtkTimer.start()
			state_machine.travel("Attack1")
		elif Input.is_action_just_pressed("attack") and AtkNumber == 2:
			is_attacking = true
			AtkTimer.start()
			state_machine.travel("Attack2")
		elif Input.is_action_just_pressed("attack") and AtkNumber == 1:
			is_attacking = true
			AtkTimer.start()
			state_machine.travel("Attack3")
	else:  # Untuk serangan jarak jauh
		if Input.is_action_just_pressed("attack") and not is_attacking:
			is_attacking = true
			AtkTimer.start()
			state_machine.travel("Cast")
			var instance = Projectile.instantiate()
			add_sibling(instance)

func remove_atknumb():
	AtkNumber -= 1

func finished_attacking():
	is_attacking = false

func move():
	move_and_slide()

func _on_attack_timer_timeout():
	AtkNumber = 3
	is_attacking = false

func _on_attack_detector_area_entered(area: Area2D) -> void:
	if area.is_in_group("Enemy"):
		Health -= area.get_parent().attackpow
		knockback = knockback.move_toward(Vector2.ZERO, 100)
		knockback = area.get_parent().knockback_dir * area.get_parent().knockback_strength
		emit_signal("health_changed", Health)

func _on_sword_hit_box_area_entered(area: Area2D) -> void:
	if area.is_in_group("Enemy"):
		area.get_parent().knockback = knockback_dir * knockback_strength
		area.get_parent().health -= attackpow
		emit_signal("enemy_attacked")

func Death():
	queue_free()
