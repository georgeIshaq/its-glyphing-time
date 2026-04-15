extends Node2D
# Flashing warning indicator where an enemy is about to spawn

var lifetime: float = 0.6
var elapsed: float = 0.0

func _process(delta: float) -> void:
	elapsed += delta
	if elapsed >= lifetime:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	var progress: float = elapsed / lifetime
	var pulse: float = abs(sin(progress * PI * 4.0))
	var alpha: float = pulse * (1.0 - progress)
	var size: float = 20.0 * (1.0 + progress * 0.5)

	# Flashing red diamond
	var color := Color(1.0, 0.3, 0.3, alpha)
	var points := PackedVector2Array([
		Vector2(0, -size),
		Vector2(size, 0),
		Vector2(0, size),
		Vector2(-size, 0),
	])
	draw_colored_polygon(points, color)

	# Outer ring
	var ring_color := Color(1.0, 0.2, 0.2, alpha * 0.5)
	for i in range(8):
		var angle: float = TAU * float(i) / 8.0
		var from: Vector2 = Vector2.RIGHT.rotated(angle) * size * 1.3
		var to: Vector2 = Vector2.RIGHT.rotated(angle) * size * 1.8
		draw_line(from, to, ring_color, 2.0)
