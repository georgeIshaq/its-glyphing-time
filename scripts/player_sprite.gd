extends Node2D
# Draws the player as a glowing diamond/chevron shape

var color: Color = Color(0.3, 0.8, 1.0)
var glow_color: Color = Color(0.4, 0.9, 1.0, 0.3)
var size: float = 16.0

func _draw() -> void:
	# Outer glow
	var glow_points: PackedVector2Array = _get_shape_points(size * 1.4)
	draw_colored_polygon(glow_points, glow_color)

	# Main body
	var body_points: PackedVector2Array = _get_shape_points(size)
	draw_colored_polygon(body_points, color)

	# Inner bright core
	var core_points: PackedVector2Array = _get_shape_points(size * 0.5)
	draw_colored_polygon(core_points, Color(1, 1, 1, 0.8))

func _get_shape_points(s: float) -> PackedVector2Array:
	# Diamond / arrow shape pointing right
	return PackedVector2Array([
		Vector2(s, 0),       # tip (right)
		Vector2(0, -s * 0.6),  # top
		Vector2(-s * 0.6, 0),  # back
		Vector2(0, s * 0.6),   # bottom
	])
