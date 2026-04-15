extends Area2D

@export var speed: float = 500.0
@export var direction: Vector2 = Vector2.RIGHT
@export var lifetime: float = 1.0
@export var damage: int = 1

var element: String = "fire"
var pierce: bool = false
var homing: bool = false
var homing_strength: float = 4.0

@onready var particles: GPUParticles2D = $GPUParticles2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

	_setup_particles()
	particles.emitting = true

	var timer: Timer = Timer.new()
	timer.one_shot = true
	timer.wait_time = lifetime
	add_child(timer)
	timer.timeout.connect(_on_lifetime_expired)
	timer.start()

func _process(delta: float) -> void:
	# Homing: steer toward nearest enemy
	if homing:
		var nearest: Node2D = _find_nearest_enemy()
		if nearest:
			var desired: Vector2 = (nearest.global_position - global_position).normalized()
			direction = direction.normalized().lerp(desired, homing_strength * delta).normalized()

	if speed > 0.0:
		if direction.length() < 0.001:
			direction = Vector2.RIGHT
		global_position += direction.normalized() * speed * delta
		rotation = direction.angle()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		return

	if body.has_method("take_damage"):
		body.take_damage(damage, element)
		_spawn_impact()

	if not pierce:
		queue_free()

func _spawn_impact() -> void:
	var impact := GPUParticles2D.new()
	impact.emitting = false
	impact.amount = 10
	impact.lifetime = 0.3
	impact.one_shot = true
	impact.explosiveness = 1.0

	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 0, 0)
	mat.spread = 180.0
	mat.initial_velocity_min = 50.0
	mat.initial_velocity_max = 120.0
	mat.gravity = Vector3.ZERO
	mat.scale_min = 1.5
	mat.scale_max = 3.5
	mat.damping_min = 50.0
	mat.damping_max = 80.0

	match element:
		"fire": mat.color = Color(1.0, 0.5, 0.1)
		"ice": mat.color = Color(0.5, 0.85, 1.0)
		"lightning": mat.color = Color(1.0, 1.0, 0.4)
		_: mat.color = Color.WHITE

	impact.process_material = mat
	impact.global_position = global_position
	get_tree().current_scene.add_child(impact)
	impact.emitting = true
	get_tree().create_timer(0.8).timeout.connect(impact.queue_free)

func _on_lifetime_expired() -> void:
	queue_free()

func _find_nearest_enemy() -> Node2D:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var nearest: Node2D = null
	var nearest_dist: float = INF

	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var dist: float = global_position.distance_to(enemy.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = enemy

	return nearest

func _setup_particles() -> void:
	particles.amount = 16
	particles.lifetime = 0.25
	particles.one_shot = false
	particles.explosiveness = 0.0
	particles.randomness = 0.4
	particles.speed_scale = 1.0
	particles.emitting = false

	var material: ParticleProcessMaterial = ParticleProcessMaterial.new()
	material.direction = Vector3(-1, 0, 0)
	material.initial_velocity_min = 5.0
	material.initial_velocity_max = 20.0
	material.scale_min = 2.0
	material.scale_max = 4.0
	material.angular_velocity_min = -30.0
	material.angular_velocity_max = 30.0
	material.gravity = Vector3.ZERO

	match element:
		"fire":
			material.color = Color(1.0, 0.45, 0.1, 1.0)
		"ice":
			material.color = Color(0.45, 0.85, 1.0, 1.0)
		"lightning":
			material.color = Color(1.0, 0.95, 0.3, 1.0)
		_:
			material.color = Color(1, 1, 1, 1)

	particles.process_material = material
