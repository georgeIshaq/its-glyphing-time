extends CharacterBody2D

@export var move_speed: float = 120.0
@export var hp: int = 3
@export var enemy_type: String = "basic"

var knockback_velocity: Vector2 = Vector2.ZERO

func _ready() -> void:
	add_to_group("enemies")
	# Configure sprite type
	var sprite = get_node_or_null("Sprite2D")
	if sprite and sprite.has_method("_draw"):
		sprite.enemy_type = enemy_type

func _physics_process(delta: float) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return

	var dir: Vector2 = (player.global_position - global_position).normalized()

	# Apply knockback decay
	knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, 8.0 * delta)

	velocity = dir * move_speed + knockback_velocity
	move_and_slide()

func take_damage(amount: int, element: String) -> void:
	hp -= amount

	# Knockback away from damage source
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var kb_dir: Vector2 = (global_position - player.global_position).normalized()
		knockback_velocity = kb_dir * 300.0

	# Element-specific effects
	match element:
		"ice":
			move_speed *= 0.6  # Slow on ice hit
		"lightning":
			knockback_velocity *= 1.5  # Extra knockback

	# Hit flash
	_flash_hit(element)

	# Spawn damage number
	_spawn_damage_number(amount, element)

	if hp <= 0:
		_die(element)

func _die(element: String) -> void:
	_spawn_death_particles(element)
	queue_free()

func _flash_hit(element: String) -> void:
	var sprite: Node = get_node_or_null("Sprite2D")
	if sprite == null:
		return
	sprite.modulate = Color(1, 1, 1)
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color(1, 0.3, 0.3), 0.05)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.15)

func _spawn_damage_number(amount: int, element: String) -> void:
	var label := Label.new()
	label.text = str(amount)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 16)

	match element:
		"fire":
			label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.1))
		"ice":
			label.add_theme_color_override("font_color", Color(0.4, 0.85, 1.0))
		"lightning":
			label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.3))
		_:
			label.add_theme_color_override("font_color", Color.WHITE)

	label.global_position = global_position + Vector2(-10, -30)
	get_tree().current_scene.add_child(label)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 40.0, 0.6)
	tween.tween_property(label, "modulate:a", 0.0, 0.6)
	tween.set_parallel(false)
	tween.tween_callback(label.queue_free)

func _spawn_death_particles(element: String) -> void:
	var particles := GPUParticles2D.new()
	particles.emitting = false
	particles.amount = 20
	particles.lifetime = 0.5
	particles.one_shot = true
	particles.explosiveness = 1.0

	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 0, 0)
	mat.spread = 180.0
	mat.initial_velocity_min = 80.0
	mat.initial_velocity_max = 200.0
	mat.gravity = Vector3(0, 200, 0)
	mat.scale_min = 2.0
	mat.scale_max = 5.0
	mat.damping_min = 20.0
	mat.damping_max = 40.0

	match element:
		"fire":
			mat.color = Color(1.0, 0.45, 0.1)
		"ice":
			mat.color = Color(0.45, 0.85, 1.0)
		"lightning":
			mat.color = Color(1.0, 0.95, 0.3)
		_:
			mat.color = Color(1.0, 0.3, 0.3)

	particles.process_material = mat
	particles.global_position = global_position
	get_tree().current_scene.add_child(particles)
	particles.emitting = true

	# Clean up after particles finish
	var timer := get_tree().create_timer(1.0)
	timer.timeout.connect(particles.queue_free)
