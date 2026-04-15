extends CharacterBody2D

signal health_changed(current: int, maximum: int)
signal player_died

@export var move_speed: float = 260.0
@export var max_hp: int = 5
@export var invincibility_time: float = 1.0
@export var contact_damage_cooldown: float = 0.5

var hp: int = 5
var invincible: bool = false
var contact_timer: float = 0.0
var facing_angle: float = 0.0

func _ready() -> void:
	hp = max_hp
	health_changed.emit(hp, max_hp)

func _physics_process(delta: float) -> void:
	var input_vector := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	)

	if input_vector.length() > 1.0:
		input_vector = input_vector.normalized()

	velocity = input_vector * move_speed
	move_and_slide()

	# Rotate sprite toward movement direction
	if input_vector.length() > 0.1:
		var target_angle: float = input_vector.angle()
		facing_angle = lerp_angle(facing_angle, target_angle, 10.0 * delta)
	var sprite = get_node_or_null("Sprite2D")
	if sprite:
		sprite.rotation = facing_angle

	# Check for enemy contact damage
	if contact_timer > 0.0:
		contact_timer -= delta
	else:
		for i in range(get_slide_collision_count()):
			var collision = get_slide_collision(i)
			var collider = collision.get_collider()
			if collider and collider.is_in_group("enemies"):
				take_damage(1)
				contact_timer = contact_damage_cooldown
				break

func take_damage(amount: int) -> void:
	if invincible:
		return

	hp -= amount
	hp = max(hp, 0)
	health_changed.emit(hp, max_hp)

	if hp <= 0:
		player_died.emit()
		return

	# Brief invincibility after being hit
	invincible = true
	_flash_damage()

	var timer := get_tree().create_timer(invincibility_time)
	timer.timeout.connect(func(): invincible = false)

func _flash_damage() -> void:
	var sprite: Node = get_node_or_null("Sprite2D")
	if sprite == null:
		return
	# Flash red then blink
	sprite.modulate = Color(1, 0.2, 0.2)
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.15)
	tween.tween_property(sprite, "modulate", Color(1, 1, 1, 0.3), 0.1)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)
	tween.tween_property(sprite, "modulate", Color(1, 1, 1, 0.3), 0.1)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)

func heal(amount: int) -> void:
	hp = min(hp + amount, max_hp)
	health_changed.emit(hp, max_hp)
