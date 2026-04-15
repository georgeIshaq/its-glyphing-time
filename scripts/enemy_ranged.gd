extends "res://scripts/enemy_basic.gd"
# Ranged enemy: keeps distance and shoots at the player

var shoot_timer: float = 2.0
var shoot_cooldown: float = 2.5
var preferred_distance: float = 300.0

const PROJECTILE_SCENE := preload("res://spells/SpellProjectile.tscn")

func _ready() -> void:
	super._ready()
	move_speed = 90.0
	hp = 2
	enemy_type = "ranged"

func _physics_process(delta: float) -> void:
	_process_status_effects(delta)
	if is_frozen:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return

	var to_player: Vector2 = player.global_position - global_position
	var dist: float = to_player.length()
	var dir: Vector2 = to_player.normalized()

	# Flip sprite to face the player
	var sprite = get_node_or_null("Sprite2D")
	if sprite and sprite is AnimatedSprite2D:
		sprite.flip_h = dir.x > 0

	# Try to maintain preferred distance
	knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, 8.0 * delta)
	if dist < preferred_distance - 50.0:
		# Too close, back away
		velocity = -dir * move_speed + knockback_velocity
	elif dist > preferred_distance + 50.0:
		# Too far, approach
		velocity = dir * move_speed + knockback_velocity
	else:
		# Circle strafe at preferred distance
		var strafe: Vector2 = dir.rotated(PI / 2.0)
		velocity = strafe * move_speed * 0.5 + knockback_velocity

	move_and_slide()

	# Shooting
	shoot_timer -= delta
	if shoot_timer <= 0.0 and dist < 500.0:
		shoot_timer = shoot_cooldown
		_shoot_at_player(dir)

func _shoot_at_player(dir: Vector2) -> void:
	var projectile = PROJECTILE_SCENE.instantiate()
	projectile.global_position = global_position + dir * 20.0
	projectile.direction = dir
	projectile.speed = 300.0
	projectile.damage = 1
	projectile.lifetime = 2.0
	projectile.element = "enemy"
	# Enemy projectiles should hit the player
	projectile.set_collision_mask_value(1, true)
	get_tree().current_scene.add_child(projectile)
