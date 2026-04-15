extends CharacterBody2D

@export var move_speed: float = 120.0
@export var hp: int = 3

func _ready() -> void:
	add_to_group("enemies")

func _physics_process(_delta: float) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return

	var dir: Vector2 = (player.global_position - global_position).normalized()
	velocity = dir * move_speed
	move_and_slide()

func take_damage(amount: int, element: String) -> void:
	hp -= amount
	print("Enemy hit by", element, "for", amount)

	if hp <= 0:
		queue_free()
