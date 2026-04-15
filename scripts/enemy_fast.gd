extends "res://scripts/enemy_basic.gd"
# Fast enemy: low HP, high speed, erratic movement

var strafe_timer: float = 0.0
var strafe_dir: float = 1.0

func _ready() -> void:
	super._ready()
	move_speed = 220.0
	hp = 1
	enemy_type = "fast"
	var sprite = get_node_or_null("Sprite2D")
	if sprite:
		sprite.enemy_type = "fast"

func _physics_process(delta: float) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return

	# Strafe back and forth while approaching
	strafe_timer -= delta
	if strafe_timer <= 0.0:
		strafe_dir *= -1.0
		strafe_timer = randf_range(0.3, 0.8)

	var to_player: Vector2 = (player.global_position - global_position).normalized()
	var strafe: Vector2 = to_player.rotated(PI / 2.0) * strafe_dir * 0.5

	knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, 8.0 * delta)
	velocity = (to_player + strafe).normalized() * move_speed + knockback_velocity
	move_and_slide()
