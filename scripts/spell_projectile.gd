extends Area2D

@export var speed: float = 500.0
@export var direction: Vector2 = Vector2.RIGHT
@export var lifetime: float = 1.0
@export var damage: int = 1

var element: String = "fire"

@onready var particles: GPUParticles2D = $GPUParticles2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

	_setup_particles()
	particles.emitting = true

	var timer: Timer = Timer.new()
	timer.one_shot = true
	timer.wait_time = lifetime
	add_child(timer)
	timer.timeout.connect(queue_free)
	timer.start()

func _process(delta: float) -> void:
	if direction.length() < 0.001:
		direction = Vector2.RIGHT

	global_position += direction.normalized() * speed * delta
	rotation = direction.angle()

func _on_body_entered(body: Node) -> void:
	print("projectile hit body:", body.name)

	if body.has_method("take_damage"):
		body.take_damage(damage, element)

	queue_free()

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
