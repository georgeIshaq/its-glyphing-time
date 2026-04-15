extends CharacterBody2D

@export var move_speed: float = 120.0
@export var hp: int = 3
@export var enemy_type: String = "basic"

const HEALTH_PICKUP_SCENE := preload("res://scenes/HealthPickup.tscn")

var knockback_velocity: Vector2 = Vector2.ZERO
var base_move_speed: float = 120.0
var burn_timer: float = 0.0
var burn_damage_timer: float = 0.0
var freeze_timer: float = 0.0
var is_frozen: bool = false

func _ready() -> void:
	add_to_group("enemies")
	base_move_speed = move_speed
	# Configure sprite type
	var sprite = get_node_or_null("Sprite2D")
	if sprite and sprite.has_method("_draw"):
		sprite.enemy_type = enemy_type

func _physics_process(delta: float) -> void:
	# Status effect timers
	_process_status_effects(delta)

	if is_frozen:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return

	var dir: Vector2 = (player.global_position - global_position).normalized()

	# Apply knockback decay
	knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, 8.0 * delta)

	velocity = dir * move_speed + knockback_velocity
	move_and_slide()

func _process_status_effects(delta: float) -> void:
	# Burn DOT
	if burn_timer > 0.0:
		burn_timer -= delta
		burn_damage_timer -= delta
		if burn_damage_timer <= 0.0:
			burn_damage_timer = 0.5
			hp -= 1
			_spawn_damage_number(1, "fire")
			_spawn_burn_particle()
			if hp <= 0:
				_die("fire")
				return
		# Tint orange while burning
		var sprite = get_node_or_null("Sprite2D")
		if sprite:
			sprite.modulate = Color(1.0, 0.6, 0.3)
	else:
		burn_damage_timer = 0.0

	# Freeze/slow
	if freeze_timer > 0.0:
		freeze_timer -= delta
		if freeze_timer <= 0.0:
			is_frozen = false
			move_speed = base_move_speed
			var sprite = get_node_or_null("Sprite2D")
			if sprite:
				sprite.modulate = Color.WHITE

func _spawn_burn_particle() -> void:
	var p := GPUParticles2D.new()
	p.emitting = false
	p.amount = 6
	p.lifetime = 0.3
	p.one_shot = true
	p.explosiveness = 1.0
	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, -1, 0)
	mat.spread = 45.0
	mat.initial_velocity_min = 30.0
	mat.initial_velocity_max = 60.0
	mat.gravity = Vector3(0, -50, 0)
	mat.scale_min = 1.5
	mat.scale_max = 3.0
	mat.color = Color(1.0, 0.5, 0.1)
	p.process_material = mat
	p.global_position = global_position
	get_tree().current_scene.add_child(p)
	p.emitting = true
	get_tree().create_timer(0.8).timeout.connect(p.queue_free)

func take_damage(amount: int, element: String) -> void:
	hp -= amount

	# Knockback away from damage source
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var kb_dir: Vector2 = (global_position - player.global_position).normalized()
		knockback_velocity = kb_dir * 300.0

	# Element-specific effects
	match element:
		"fire":
			# Apply burn DOT (2 seconds of periodic damage)
			burn_timer = 2.0
			burn_damage_timer = 0.5
		"ice":
			# Slow and potentially freeze
			move_speed = base_move_speed * 0.4
			freeze_timer = 1.5
			var sprite = get_node_or_null("Sprite2D")
			if sprite:
				sprite.modulate = Color(0.5, 0.7, 1.0)
			# If already slowed, freeze solid
			if move_speed < base_move_speed * 0.5:
				is_frozen = true
				freeze_timer = 2.0
		"lightning":
			knockback_velocity *= 1.5  # Extra knockback
			# Chain lightning to nearby enemies
			_chain_lightning(amount)

	# Hit flash
	_flash_hit(element)

	# Spawn damage number
	_spawn_damage_number(amount, element)

	if hp <= 0:
		_die(element)

func _chain_lightning(damage_amount: int) -> void:
	var chain_range: float = 120.0
	var enemies = get_tree().get_nodes_in_group("enemies")

	for enemy in enemies:
		if enemy == self or not is_instance_valid(enemy):
			continue
		if global_position.distance_to(enemy.global_position) <= chain_range:
			# Visual: draw a brief lightning line
			_spawn_lightning_arc(global_position, enemy.global_position)
			# Deal reduced chain damage (don't chain recursively)
			enemy.hp -= max(damage_amount - 1, 1)
			enemy._flash_hit("lightning")
			enemy._spawn_damage_number(max(damage_amount - 1, 1), "lightning")
			if enemy.hp <= 0:
				enemy._die("lightning")
			break  # Only chain to one target

func _spawn_lightning_arc(from: Vector2, to: Vector2) -> void:
	var line := Line2D.new()
	line.width = 2.0
	line.default_color = Color(1.0, 1.0, 0.4, 0.9)

	# Jagged line between points
	var segments: int = 6
	for i in range(segments + 1):
		var t: float = float(i) / float(segments)
		var pos: Vector2 = from.lerp(to, t)
		if i > 0 and i < segments:
			pos += Vector2(randf_range(-10, 10), randf_range(-10, 10))
		line.add_point(pos)

	get_tree().current_scene.add_child(line)
	var tween := line.create_tween()
	tween.tween_property(line, "modulate:a", 0.0, 0.15)
	tween.tween_callback(line.queue_free)

func _die(element: String) -> void:
	_spawn_death_particles(element)
	_maybe_drop_health()
	queue_free()

func _maybe_drop_health() -> void:
	if randf() < 0.15:  # 15% chance
		var pickup = HEALTH_PICKUP_SCENE.instantiate()
		pickup.global_position = global_position
		get_tree().current_scene.call_deferred("add_child", pickup)

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

	# Tween must be bound to the label, not the enemy --
	# the enemy may die before the animation finishes
	var tween := label.create_tween()
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
