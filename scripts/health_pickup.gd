extends Area2D

var float_time: float = 0.0
var base_y: float = 0.0
var heal_amount: int = 1

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	base_y = global_position.y

	# Auto-despawn after 10 seconds
	var timer := Timer.new()
	timer.one_shot = true
	timer.wait_time = 10.0
	add_child(timer)
	timer.timeout.connect(_fade_out)
	timer.start()

func _process(delta: float) -> void:
	float_time += delta * 3.0
	global_position.y = base_y + sin(float_time) * 4.0
	queue_redraw()

func _draw() -> void:
	# Green glowing cross/plus shape
	var s: float = 6.0
	draw_circle(Vector2.ZERO, s * 1.5, Color(0.2, 1.0, 0.3, 0.2))  # glow
	draw_rect(Rect2(-s, -s * 0.3, s * 2, s * 0.6), Color(0.3, 1.0, 0.4))  # horizontal
	draw_rect(Rect2(-s * 0.3, -s, s * 0.6, s * 2), Color(0.3, 1.0, 0.4))  # vertical

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("heal"):
		body.heal(heal_amount)
		var audio = get_node_or_null("/root/Main/AudioManager")
		if audio:
			audio.play("health_pickup")
		queue_free()

func _fade_out() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(queue_free)
